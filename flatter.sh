#!/bin/bash
#
# create additional flat networks
# see --help for more information on the parameters
# 
# rschmied@cisco.com
# 

function bail_out() {
        echo "@@@ $1"
        echo "@@@ aborted."
        exit 1
}

function get_a_yes() {
	local __resultvar=$1
	local line result

	echo -en "\n$2 (y/yes)? "
	read line
	if [[ "$line" =~ ^(y|yes)$ ]]; then
		result="yes"
	else
		result="no"
	fi
	eval $__resultvar="'$result'"
}

# create network entry in /etc/network/interfaces
function add_interface() {
	local ok change

	change=$(echo "auto INTFC
	iface INTFC inet static
	    address ADDRESS
	    netmask MASK
	    post-up ip link set INTFC promisc on
	" | sed -e "s/^\t//" -e "s/INTFC/$1/" -e "s/ADDRESS/$2/" -e "s/MASK/$3/")

	echo "@@@ Proposed change:"
	echo "$change"
	get_a_yes ok "@@@ apply changes"
	if [ $ok = "yes" ]; then 
		echo "$change" >>/etc/network/interfaces
		ifconfig $1 0 0 down
		ifup $1
	else
		echo "@@@ not applied."
		#exit 1
	fi
}

function restart_neutron() {
        echo "@@@ Stopping Neutron services"
        for i in /etc/init/neutron-*; do service $(basename $i | sed -e 's/.conf//' ) stop; done
	echo "@@@ wait a bit"
	sleep 2
        echo "@@@ Starting Neutron services"
        for i in /etc/init/neutron-*; do service $(basename $i | sed -e 's/.conf//' ) start; done
        echo -n "@@@ Waiting "
        while [[ $(neutron 2>&1 agent-list) =~ failed ]]; do sleep 1; echo -n "."; done
        echo " done."
}

#
# "add" / "del"
# file
# section
# varname
# value
#
function mod_config() {
	local var newvar

	var=$(crudini --get $2 $3 $4)
	if [ -z $var ]; then
		echo "@@@ var $4 in section $3 in file $2 not found!"
		rollback
	fi
	if [ "$1" = "add" ]; then
		if [[ "$var" =~ $5 ]]; then
			echo "@@@ var $4 in section $3 in file $2:"
			echo "@@@ FLAT network $4 is already there!"
			echo "@@@ can't add. Bailing out..."
			rollback
		else
			newvar=$var,$5
		fi
	else
		if ! [[ "$var" =~ $5 ]]; then
			echo "@@@ var $4 in section $3 in file $2:"
			echo "@@@ FLAT network $4 is NOT there!"
			echo "@@@ can't delete. Bailing out..."
			rollback
		else
			newvar=$(echo $var | sed -e 's/\,'$5'//')
		fi
	fi
	crudini --set --existing $2 $3 $4 $newvar
	if [ $? -ne 0 ]; then
		echo "@@@ var $4 in section $3 in file $2:"
		echo "@@@ setting the value failed!"
		echo "@@@ bailing out..."
		rollback
	fi
}


function remove_flat() {
	# only proceed if net is there and active
        if [ -z "$(ip route | grep -e "^$PREFIX dev ")" ]; then
                echo "@@@ Prefix not in routing table"
                return
        fi

	# delete net (and implicitely the subnet)
	if [[ $(neutron 2>&1 net-show $FLAT_NAME) =~ Unable.to.show ]]; then
		echo "@@@ Neutron network $FLAT_NAME doesn't exist"
		return
	fi
	echo "@@@ Delete Neutron network $FLAT_NAME"
	neutron net-delete $FLAT_NAME

        # change Neutron configuration
        mod_config del $BRIDGE_DIR/$BRIDGE_INI vlans network_vlan_ranges $FLAT_NAME
        mod_config del $BRIDGE_DIR/$BRIDGE_INI linux_bridge physical_interface_mappings $FLAT_NAME:$PHY_NAME
        mod_config del $ML2_DIR/$ML2_INI ml2_type_flat flat_networks $FLAT_NAME

	echo "@@@ Wait a few to allow for network to settle"
	sleep 2
	ifdown $PHY_NAME

	echo "@@@ Removing interface configuration from /etc/network/interfaces"
	sed -i -e "/^auto $PHY_NAME/d" -e "/^iface $PHY_NAME inet static/,+4d" /etc/network/interfaces

	restart_neutron
}


function add_flat() {

	# add interface to system network configuration
	add_interface $PHY_NAME $IFACE_IP $IFACE_MASK
	if [ -z "$(ip route | grep -e "^$PREFIX dev $PHY_NAME")" ]; then
		echo "@@@ Something went wrong!"
		echo "@@@ $PHY_NAME seems not to be up with the given prefix $PREFIX"
		rollback
	fi

	# change Neutron configuration
	echo "@@@ Changing Neutron configuration"
	mod_config add $BRIDGE_DIR/$BRIDGE_INI vlans network_vlan_ranges $FLAT_NAME
	mod_config add $BRIDGE_DIR/$BRIDGE_INI linux_bridge physical_interface_mappings $FLAT_NAME:$PHY_NAME
	mod_config add $ML2_DIR/$ML2_INI ml2_type_flat flat_networks $FLAT_NAME

	restart_neutron

	# create Neutron network and subnet
	echo "@@@ Creating networks"
	neutron net-create --shared --provider:physical_network=$FLAT_NAME --provider:network_type=flat $FLAT_NAME
	neutron subnet-create $FLAT_NAME --name $FLAT_NAME \
	  --allocation-pool start=$DHCP_FIRST,end=$DHCP_LAST \
	  --gateway $GATEWAY $PREFIX \
	  --dns-nameservers list=true $NAMESERVERS

	restart_neutron
}

function rollback() {
	echo "@@@ Rolling back config files..."
	cp $BACKUP_DIR/interfaces /etc/network/interfaces
	cp $BACKUP_DIR/$ML2_INI $ML2_DIR/$ML2_INI
	cp $BACKUP_DIR/$BRIDGE_INI $BRIDGE_DIR/$BRIDGE_INI
	echo "@@@ Cleaning up"
	rm -rf $BACKUP
	bail_out
}

function usage() {
	local name=$(basename $0)
	cat <<-EOF
	
	Usage:
	 $name physical_interface_name flat_network_name ipv4_network_prefix [options]
	
	Options:
	 -d, --dns		Nameservers, space separted and in quotes
	 -f, --first		First IP of DHCP scope, relative to prefix
	 --force		With --remove only, omits some input validation
	 -g, --gateway		Gateway IP, relative to prefix
	 -h, --help		Print this information
	 -i, --interface	Interface IP, relative to prefix
	 -l, --last		Last IP of DHCP scope, relative to prefix
	 -n, --neutron		Restart Neutron services (as a single option only)
	 -r, --remove		Remove specified flat network, other options ignored

	Examples:
	 $name eth1 flat3 172.16.6.0/24
	 $name eth1 flat3 172.16.6.0/24 -i last-1 -f first+50 -l last-2 -g first+1
	 $name eth2 flat2 192.168.255.64/26 -f first+16
	 $name eth9 flat4 11.0.0.0/8 --interface=last-1 -f first+50 -l last-2 -g first+1
	 $name eth1 flat5 172.16.20.0/22 --dns="1.2.3.4 5.6.7.8"
	 $name eth1 flat5 172.16.20.0/22 -d 1.2.3.4
	 $name eth1 flat5 172.16.20.0/22 --remove
	 $name --neutron
	
	Defaults:
	 --first=first+50 --last=last-2 
	 --interface=last-1 --gateway=first+1
	 --dns="8.8.8.8 8.8.4.4"

	Relative IP Address:
	 Addresses are relative to scope and calculated using simple +/- arithmetic
	 first, first+1, first+10, last-5
	 first+2 for the gateway is usually the NAT in a VMware Workstation / Fusion environment

	Caveats:
	 Potentially not every invalid parameter mutation will be caught! Be careful!
	 Prefix length must be < 26.
	
	EOF
	exit 1
}

# main

#set -vx
shopt -s nocasematch;

# defaults
NAMESERVERS="8.8.8.8 8.8.4.4"
DHCP_FIRST="first+50"
DHCP_LAST="last-2"
IFACE_IP="last-1"
GATEWAY="first+1"

PLUGIN_DIR=/etc/neutron/plugins
BRIDGE_DIR=$PLUGIN_DIR/linuxbridge
BRIDGE_INI=linuxbridge_conf.ini
ML2_DIR=$PLUGIN_DIR/ml2
ML2_INI=ml2_conf.ini

# extract options and their arguments into variables.
TEMP=$(getopt -o d:f:g:hi:l:nr --long dns:,first:,force,gateway:,help,interface:,last:,neutron,remove -n "$0" -- "$@")
eval set -- "$TEMP"
while true ; do
    case "$1" in
        -d|--dns)
	    case "$2" in
		"") shift 2 ;;
		*) NAMESERVERS=$2 ;  shift 2 ;;
	    esac ;;
        -f|--first)
	    case "$2" in
		"") shift 2 ;;
		*) DHCP_FIRST=$2 ;  shift 2 ;;
	    esac ;;
	--force) FORCE="yes"; shift ;;
        -g|--gateway)
	    case "$2" in
		"") shift 2 ;;
		*) GATEWAY=$2 ;  shift 2 ;;
	    esac ;;
        -h|--help) usage; shift ;;
        -i|--interface)
	    case "$2" in
		"") shift 2 ;;
		*) IFACE_IP=$2 ;  shift 2 ;;
	    esac ;;
        -l|--last)
	    case "$2" in
		"") shift 2 ;;
		*) DHCP_LAST=$2 ;  shift 2 ;;
	    esac ;;
        -n|--neutron) RESTART_NEUTRON="yes"; shift ;;
        -r|--remove) REMOVE="yes"; shift ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

# special case
if [ -n "$RESTART_NEUTRON" ]; then
	restart_neutron
	exit 0
fi

# three mandatory arguments: physical interface name, flat network name and IP prefix
[ $# -lt 3 ] && usage

PHY_NAME=$1
FLAT_NAME=$2
PREFIX=$3

# python netaddr to the rescue
read PREFIX IFACE_NET IFACE_MASK IFACE_MASKLEN IFACE_IP DHCP_FIRST DHCP_LAST GATEWAY <<< $(python -c \
	"from netaddr import *; ip=IPNetwork(\"$PREFIX\"); \\
	print ''.join([str(ip.network), \"/\", str(ip.prefixlen)]), ip.network, ip.netmask, ip.prefixlen, \\
	IPAddress(ip.$IFACE_IP), IPAddress(ip.$DHCP_FIRST), IPAddress(ip.$DHCP_LAST), IPAddress(ip.$GATEWAY)")

# do we miss anything?
if [ -z "$PREFIX" -o -z "$IFACE_NET" -o -z "$IFACE_MASK" -o -z "$IFACE_MASKLEN" -o \
     -z "$IFACE_IP" -o -z "$DHCP_FIRST" -o -z "$DHCP_LAST" -o -z "$GATEWAY" ]; then
	usage
fi

# need a little space for DHCP scope
if [ $IFACE_MASKLEN -gt 26 ]; then
	usage
fi

# input check 
if [ -n "$REMOVE" -a -z "$FORCE" ]; then
	l=$(brctl show | grep -e "$PHY_NAME")
	[ -z "$l" ] && bail_out "device $PHY_NAME NOT present on any bridge"
	re="$PREFIX dev $(echo $l | cut -d' ' -f1)"
	! [[ "$(ip route)" =~ $re ]] && bail_out "bridge with $PHY_NAME and $PREFIX do not match" 
	[[ "$(neutron 2>&1 net-show $FLAT_NAME)" =~ "Unable to find network" ]] && bail_out "Neutron net $FLAT_NAME unknown"
	! [[ "$(neutron 2>&1 subnet-show "$FLAT_NAME")" =~ cidr.*$PREFIX ]] && bail_out "Neutron subnet $FLAT_NAME does not match $PREFIX"
elif [ -z "$REMOVE" ]; then
	[[ "$(ifconfig 2>&1 $PHY_NAME)" =~ "$PHY_NAME: error fetching interface information: Device not found" ]] && bail_out "device $PHY_NAME is not valid"
	[ -n "$(ip route | grep -e "dev $PHY_NAME")" ] && bail_out "device $PHY_NAME present in routing table"
	[ -n "$(brctl show | grep -e "$PHY_NAME")" ] && bail_out "device $PHY_NAME present on a bridge"
fi

# check with user
echo "@@@ What we've got so far:"
echo -e "Interface name:    $PHY_NAME"
echo -e "Net/Subnet Name:   $FLAT_NAME"
echo -e "IP Prefix:         $PREFIX"
if [ -z "$REMOVE" ]; then
	echo -e "Interface network: $IFACE_NET"
	echo -e "Interface mask:    $IFACE_MASK"
	echo -e "Mask length:       $IFACE_MASKLEN"
	echo -e "Interface IP:      $IFACE_IP"
	echo -e "DHCP Start:        $DHCP_FIRST"
	echo -e "DHCP End:          $DHCP_LAST"
	echo -e "Gateway:           $GATEWAY"
	echo -e "DNS:               $NAMESERVERS"
fi

get_a_yes ok "@@@ Go ahead"
[ $ok = "no" ] && bail_out

# make backup of files that are going to be changed
echo "@@@ Making backup for rollback"
BACKUP_DIR=$(mktemp --dir)
cp /etc/network/interfaces $BACKUP_DIR/
cp $ML2_DIR/$ML2_INI $BACKUP_DIR/
cp $BRIDGE_DIR/$BRIDGE_INI $BACKUP_DIR/

if [ -z "$REMOVE" ]; then
	add_flat
else
	remove_flat
fi

echo "@@@ Cleaning up"
rm -rf $BACKUP_DIR
exit 0

