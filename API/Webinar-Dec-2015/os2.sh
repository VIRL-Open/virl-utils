#!/bin/bash

HOST="172.16.1.1"

curl -s -H "X-Auth-Token:6372b01430964f76bd8f8047e1daef26" \
	http://$HOST:8774/v2/774f2d67cd0d4c829f3cbcedb026ee83/flavors \
	| python -m json.tool


