#!/bin/bash
# 
# Create a named pipe and attach the output of a remote
# tcpdump to it (running on the VIRL host). Would require
# the correct tap interface as a parameter.
# Use the list.py script to identify tap interfaces of
# running instances.
# 
# Ideally, the ssh will use a key to login to make this
# seamless.
#
# Open Wireshark and create a pipe interface via
# 'Capture Options' -> 'Manage Interfaces' -> 'New Pipe'
# and point it to /tmp/remotecapture.fifo
# (don't forget to save the pipe interface)
#
# rschmied@cisco.com
#

if [ $# == 0 ]; then
  echo "tap interface name not provided"
  exit
fi

HOST=172.16.1.1
PORT=22222
USER=virl
FIFO=/tmp/remotecapture.fifo

# make sure fifo exists
if ! [ -p $FIFO ]; then
  if [ -f $FIFO ]; then rm $FIFO; fi
  mkfifo $FIFO; 
fi

# make sure the param is indeed a tap interface
if [[ "$1" =~ ^tap[0-9a-f]{8}-[0-9a-f]{2}$ ]]; then
  /usr/bin/ssh -n >$FIFO -p $PORT $USER@$HOST sudo stdbuf -o0 tcpdump -w- -s0 -vni $1 
else
  echo "$1 does not look like a tap interface"
fi

