#!/usr/bin/env python
#
# Lists all interfaces of all VMs run by a particular
# user. The username has to provided as a paramater.
# The tap interfaces can then be used to do a traffic
# capture locally using tcpdump
#
# v0.2 02-Dec-2015 
# adapted to Kilo release
# v0.1 24-Nov-2014
# initial release
#
# rschmied@cisco.com
#

import sys, re, os, prettytable
from neutronclient.v2_0 import client
from operator import itemgetter


##	 </guest/endpoint>-<testAA-u6dRq3>-<lxc-1>-<guest>

def list_taps(user):
	out = {}

	nc = client.Client(username=os.environ['OS_USERNAME'], password=os.environ['OS_PASSWORD'],
		tenant_name=os.environ['OS_TENANT_NAME'], auth_url=os.environ['OS_SERVICE_ENDPOINT'])

	prog = re.compile(r'</('+user+')/endpoint>-<(.*)-[0-9a-zA-Z_]{6}>-<(.*)>-<(.*)>')
	ports = nc.list_ports()
	for thisport in ports['ports']:
		m = prog.match(thisport['name'])

		if m:
			(user, topo, node, connection) = (m.group(1), m.group(2), m.group(3), m.group(4))

			if not user in out:
				out[user] = {}
			if not topo in out[user]:
				out[user][topo] = []
			if connection == user:
				tmp = 'Management Network'
			else:
				tmp = connection
			out[user][topo].append({'id': thisport['id'], 
				'from': node, 'to': tmp})

	pt = prettytable.PrettyTable(["Project", "Topology", "Node", "Link", "Interface" ])
	pt.align = "l"
	
	for proj in out:
		projectname = proj.title()
		for topo in out[proj]:
			toponame = topo.title()
			out[proj][topo].sort(key=itemgetter('from'))
			for port in out[proj][topo]:
				pt.add_row([projectname, toponame, port['from'], 
					port['to'], "tap" + port['id'][0:11]])
				projectname = ""
				toponame = ""
	print pt.get_string()
	return 0


def main():
	user='.*'
	if len(sys.argv) == 2:
		user=str(sys.argv[1]).strip()
	return list_taps(user)


if __name__ == '__main__':
	sys.exit(main())

