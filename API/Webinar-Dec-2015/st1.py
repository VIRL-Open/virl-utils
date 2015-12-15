#!/usr/bin/env python

import os, requests, sys

def stop_topo(toponame):
	virl_host = "10.87.94.20"
	username  = password = "guest"
	url       = "http://%s:19399/simengine/rest/stop/%s" % (virl_host, toponame)
	headers   = {'content-type': 'text/xml'}

	result = requests.get(url, auth=(username, password), headers=headers) 
	print result.text


def main():
	if len(sys.argv) != 2:
		sys.stdout.write(str(sys.argv[0]))
		print ":  usage: st.py <simulation-name>"
		return 1                
	else:
		stop_topo(str(sys.argv[1]).strip())
		return 0


if __name__ == '__main__':
	sys.exit(main())
