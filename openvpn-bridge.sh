#!/bin/bash

# Adapt vars in this section
# get device name via 'networksetup -listnetworkserviceorder'
# or via Network Control Panel

DEVICE_NAME="FLAT USB"
ROUTE="172.16.0.0/22 172.16.1.254"
TAP=tap0
BR=bridge99

# nothing to be changed below
DEVICE=$(networksetup -listnetworkserviceorder | \
		sed -nE "/$DEVICE_NAME/{n;s/^.*: (.*))$/\1/p;}")

if ! [ "$DEVICE" ]; then
	echo "$0: device name for \"$DEVICE_NAME\" not found"
	exit
fi

if [ "$1" == "setup" ];then
	networksetup -setv6off "$DEVICE_NAME"
	networksetup -setv4off "$DEVICE_NAME"

elif [ "$1" == "create" ]; then
	# read assigned IP / mask
	read addr mask <<< $(ifconfig $TAP | awk  '/inet/{ print $2, $4 }')

	# delete route and IP on tap
	route delete $ROUTE
	ifconfig $TAP delete $addr netmask $mask

	# create bridge and add info to it
	ifconfig $BR create
	ifconfig $BR addm $TAP addm $DEVICE
	ifconfig $BR $addr netmask $mask up
	route add $ROUTE

	# MTU needs 4 bytes more (empirical value) 
	# additional IP header? Maybe transport (TCP) specific
	# (tcpump: "IP truncated-ip - 4 bytes missing!")
	# must change after devices are added to bridge
	ifconfig $TAP mtu 1504

elif [ "$1" == "destroy" ]; then
	read addr mask <<< $(ifconfig $BR | awk  '/inet/{ print $2, $4 }')
	route delete $ROUTE
	ifconfig $BR delete $addr netmask $mask
	ifconfig $BR down
	ifconfig $BR deletem $DEVICE deletem $TAP
	ifconfig $BR destroy
	ifconfig $TAP $addr netmask $mask up
	route add $ROUTE

else
	echo "$0: either 'setup', 'create' or 'destroy' needed!"
fi

