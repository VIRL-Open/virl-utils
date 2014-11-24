#!/bin/sh
# 
# Show only interfaces that have an IPv4 address
#
# rschmied@cisco.com
#

ip addr | sed -nre '{/^[0-9]+:/h;/inet ([0-9]+\.){3}[0-9]+/{x;p;x;p}}' 

