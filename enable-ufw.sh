#!/bin/bash
# vim: tabstop=4 shiftwidth=4 softtabstop=4
#
# start the User Friendly Firewall on a VIRL host
#
# v0.2 16-Dec-2015
# forwarding policy and input rules changed
# v0.1 14-Dec-2015
# initial release
# 
# rschmied@cisco.com
#


# change these to match your requirements
SSH_PORT=22
VPN_PORT=443
VPN_PROT="tcp"

################################################

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

