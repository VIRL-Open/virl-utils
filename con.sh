#!/bin/sh
#
# Connect to a console port on the VIRL host
# provide the TCP port as a parameter (i.e. 17000).
#
# To disconnect, press Ctrl-\ (and not Ctrl-[ to allow
# for a nested Telnet session
#
# rschmied@cisco.com
#

gateway=$(ip route | \
  awk '/^default / {for(i=0;i<NF;i++) {if ($i=="dev") {print $(i+1);next;}}}')

telnet -e $(ifconfig $gateway | sed -rn 's/.*r:([^ ]+) .*/\1/p') $1

