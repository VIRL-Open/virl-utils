#!/bin/bash
# 
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

if [ $# == 0 ]; then
  echo "port number not provided"
  exit
fi

HOST=172.16.1.254
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

