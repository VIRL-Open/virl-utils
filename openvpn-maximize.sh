#!/bin/bash
# vim: tabstop=4 shiftwidth=4 softtabstop=4
#
# 'maximize' OpenVPN
# - adapt virl.ini
# - set gateways for FLAT, FLAT1, EXT-NET
# - change Nova serial proxy host and STD host
# - enable firewall
# - restart all touched services
#
# v0.1 16-Dec-2015
# initial release
# 
# rschmied@cisco.com
#


# change these to match your requirements
SSH_PORT=22
VPN_PORT=443
VPN_PROT="tcp"
DNS_SRV1="8.8.8.8"
DNS_SRV2="8.8.4.4"


################################################


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

cat <<-EOF

	This script will 'maximize' the OpenVPN connection for your VIRL host. 
	It assumes that

	- you already have a working OpenVPN configuration / setup
	- you did not change the default IP address block / networks (172.16.0.0/22)
	- you did not change the default IP addresses of FLAT/FLAT1/SNAT interfaces
	- you did change the variables at the top of this script to reflect your DNS
	  and OpenVPN configuration (port, protocol, DNS addresses)

	The script does
	
	- enable the Firewall, securing the outside (only SSH and OpenVPN allowed)
	- enable NAT/PAT so that internal nodes can access the outside via the management
	  (eth0) interface
	- make STD and other services available via OpenVPN (e.g. VM Maestro can be pointed
	  to 172.16.1.254)
	- configure a uniform set of DNS servers for all internal networks
	- push additional routes for FLAT1 and SNAT to the OpenVPN clients

	The script will change various system setting and enables the Firewall on the host.
	This is a DANGEROUS operation if you're remote and something goes wrong!

	If possible, run this on the console!

EOF

get_a_yes ok "Do you want to proceed?"
[ $ok = "no" ] && exit


# make sure virl.ini is in sync
crudini --set /etc/virl.ini DEFAULT l2_network_gateway 172.16.1.254
crudini --set /etc/virl.ini DEFAULT first_flat_nameserver $DNS_SRV1
crudini --set /etc/virl.ini DEFAULT second_flat_nameserver $DNS_SRV2
crudini --set /etc/virl.ini DEFAULT l2_network_gateway2 172.16.2.254
crudini --set /etc/virl.ini DEFAULT first_flat2_nameserver $DNS_SRV1
crudini --set /etc/virl.ini DEFAULT second_flat2_nameserver $DNS_SRV2
crudini --set /etc/virl.ini DEFAULT l3_network_gateway 172.16.3.254
crudini --set /etc/virl.ini DEFAULT first_snat_nameserver $DNS_SRV1
crudini --set /etc/virl.ini DEFAULT second_snat_nameserver $DNS_SRV1

# change neutron subnets
neutron subnet-update flat --gateway_ip 172.16.1.254
neutron subnet-update flat --dns_nameservers list=true $DNS_SRV1 $DNS_SRV2

neutron subnet-update flat1 --gateway_ip 172.16.2.254
neutron subnet-update flat1 --dns_nameservers list=true $DNS_SRV1 $DNS_SRV2

neutron subnet-update ext-net --gateway_ip 172.16.3.254
neutron subnet-update ext-net --dns_nameservers list=true $DNS_SRV1 $DNS_SRV2

# change nova serial proxy and STD to listen on FLAT IP
crudini --set /etc/nova/nova.conf DEFAULT serial_port_proxyclient_address 172.16.1.254
crudini --set /etc/virl/virl.cfg env virl_local_ip 172.16.1.254

# restart services
service neutron-l3-agent restart
service nova-serialproxy restart
service virl-std restart
service virl-uwm restart


# get the network device where the default interface is attached to
gw=$(ip route | awk '/^default / { for(i=0;i<NF;i++) { if ($i == "dev") { print $(i+1); next; }}}')


# insert the NAT rule
sed -ie "/^\*filter/i\
*nat\n\
:POSTROUTING ACCEPT [0:0]\n\
\n\
# translate outbound traffic from internal networks \n\
-A POSTROUTING -s 172.16.0.0/22 -o $gw -j MASQUERADE\n\
\n\
# don't delete the 'COMMIT' line or these nat table rules won't\n\
# be processed\n\
COMMIT\n" /etc/ufw/before.rules


#
# regular UFW rules (not NAT)
#
ufw allow in on $gw to any port $SSH_PORT proto tcp
ufw allow in on $gw to any port $VPN_PORT proto $VPN_PROT

# deny / permit everything else
ufw deny in on $gw log
ufw allow from any to any

# allow forwarding of packets
ufw default allow routed

# get set user rules:
# sudo grep '^### tuple' /lib/ufw/user*.rules

# enabling the FW will make it persistent
# across reboots!
#
echo "y" | ufw enable

# show the configured rules
ufw status verbose


exit 0

