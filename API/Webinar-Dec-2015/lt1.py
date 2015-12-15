#!/usr/bin/env python

import os, requests, sys

def launch_topo(topofilename, toponame):
	virl_host = "172.16.1.1"
	username  = password = "guest"
	url       = "http://%s:19399/simengine/rest/launch" % virl_host
	topo      = open(topofilename, 'r')
	headers   = {'content-type': 'text/xml'}
	payload   = {'session': toponame}

	result = requests.post(url, auth=(username, password), params=payload, data=topo, headers=headers)
	print result.text


def main():
	if len(sys.argv) != 3:
		sys.stdout.write(str(sys.argv[0]))
		print ":  usage: lt.py <file.virl> <simulation-name>"
		return 1
	else:
		launch_topo(str(sys.argv[1]).strip(),str(sys.argv[2]).strip())
		return 0


if __name__ == '__main__':
	sys.exit(main())
