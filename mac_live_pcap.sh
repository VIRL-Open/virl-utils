#!/bin/bash

# Adapted from script created by rschmied@cisco.com
# **************************************************
# Create a named pipe and attach the output of a remote
# tcpdump to it (running on the VIRL host). Would require
# the correct TCP port the live capture is listening on.
# 
# Open Wireshark and create a pipe interface via
# 'Capture Options' -> 'Manage Interfaces' -> 'New Pipe'
# and point it to /tmp/remotecapture.fifo
# (don't forget to save the pipe interface)
#
# rschmied@cisco.com
#

# Remark this section to hard code server IP address HOST=
echo ""
echo -n "IP address of VIRL Server: "
read HOST
# Remark this section to hard code server IP address

if [ $# == 0 ]; then
  echo ""
  echo "port number not provided"
  echo "Usage: ./mac_live_pcap.sh [port number]"
  exit
fi

# Remove remark from next line and enter Server IP address
# HOST=


FIFO=/tmp/remotecapture.fifo

# make sure fifo exists
if ! [ -p $FIFO ]; then
  if [ -f $FIFO ]; then rm $FIFO; fi
  mkfifo $FIFO;
fi

# make sure the param is indeed a tap interface
if [[ "$1" =~ ^[0-9]+$ ]]; then
  /usr/bin/nc >$FIFO $HOST $1
else
	echo "$1 does not look like a port number"
fi
