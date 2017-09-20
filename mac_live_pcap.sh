#!/bin/bash

# Adapted from script created by rschmied@cisco.com
# ****************************************************************
# This script will create a named pipe and attach the output
# of a remote tcpdump; which is running on the VIRL host.
# The script only requires the TCP port number, which is passed
# as an argument.
#
# This script will now open Wireshark on your mac and
# automatically connect to the live port specified. You may also
# run concurrent Live Captures running on unique port numbers.
#
# The instructions below are only applicable should Wireshark
# fail to connect and display captured traffic.
#
##################################################################
#                   MANUAL PROCESS
##################################################################
# Open Wireshark and create a pipe interface via
# 'Capture Options' -> 'Manage Interfaces' -> 'New Pipe'
# and point it to /tmp/remotecapture.fifo
# (don't forget to save the pipe interface)
#
# modified by: alegalle@cisco.com
# last modified: Sept 20, 2017
# ****************************************************************

# Default location of Wireshark
wpcap=/usr/local/bin/wireshark

_usage()
{
cat <<EOF

    Wireshark does not appear to be installed in its default location. Ensure
    you have properly installed Wireshark or edit the script variable 'wpcap' to
    reflect its location on your system!

EOF
exit 1
}

int_exit()
{
rm $FIFO
echo -e "${PROGNAME}: Aborted by user!\n"
exit
}

term_exit()
{
rm $FIFO
echo -e "\n${PROGNAME}: Terminated!\n"
exit
}

# script start
PROGNAME=$(basename $0)
trap int_exit INT
trap term_exit TERM HUP

# Check that Wireshark is install in default location
if [ ! -e $wpcap ] ; then
    _usage
fi

if [ $# == 0 ]; then
  printf "\nYou must provide a port number with script!\nUsage: $0 [port number]\n\n"
  exit 1
fi

##  HARD CODING YOUR SERVER IP ADDRESS  ##
# To hard code your VIRL PE server's IP, remark ( prepend line with # )
# from next line to STOP marker!
echo ""
echo -n "IP address of VIRL Server: "
read HOST
# Remark STOP!

# Remove remark from HOST= line and provide your VIRL server's IP address
#HOST=

FIFO=/tmp/virl-cap_$1.fifo

# make sure fifo exists
if ! [ -p $FIFO ]; then
  if [ -f $FIFO ]; then
     rm $FIFO
  fi
  mkfifo $FIFO
fi

# make sure the param is indeed a tap interface
if [[ "$1" =~ ^[0-9]+$ ]]; then
    nohup /usr/local/bin/wireshark -k -i $FIFO &
    sleep 2
    /usr/bin/nc >$FIFO $HOST $1
else
    echo -e "Is $1 the correct port number?\nCheck port number and try again."
fi
