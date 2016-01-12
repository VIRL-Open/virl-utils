#!/usr/bin/env python
#
# Lists all interfaces of all VMs run by a particular
# project. The project name can be provided as a paramater.
# If none is provided, all projects are listed.
#
# The tap interfaces can then be used to do a traffic
# capture locally using tcpdump
#
# v0.3 02-Dec-2015 
# - changed regex to work with webeditor topologies (w/o 6-digit random id)
# - added IP column for non-infrastructure ports
# - changed 'user' to 'project' because it is
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

# </guest/endpoint>-<triangle-ghU06c>-<iosv-2>-<guest> 
# </guest/endpoint>-<trunk>-<lxc-2>-<iosvl2-1-to-lxc-2>
# </guest/endpoint>-<triangle-ghU06c>-<~mgmt-lxc>-<~lxc-flat>
# </guest/endpoint>-<jjj>-<~mgmt-lxc>-<~lxc-flat>
# </guest/endpoint>-<testAA-u6dRq3>-<lxc-1>-<guest>

def list_taps(project):
	out = {}

	nc = client.Client(username=os.environ['OS_USERNAME'], password=os.environ['OS_PASSWORD'],
		tenant_name=os.environ['OS_TENANT_NAME'], auth_url=os.environ['OS_SERVICE_ENDPOINT'])

	prog = re.compile(r'</('+project+')/endpoint>-<(.*)(?:-\w{6})?>-<(.*)>-<(.*)>')
	ports = nc.list_ports()
	for thisport in ports['ports']:
		m = prog.match(thisport['name'])
		if m:
			project, topo, node, connection = m.group(1), m.group(2), m.group(3), m.group(4)
			if not project in out:
				out[project] = {}
			if not topo in out[project]:
				out[project][topo] = []
			if connection == project:
				tmp = 'Management Network'
			else:
				tmp = connection
			ip = thisport['fixed_ips'][0]['ip_address']
			if ip in ['10.255.255.1', '10.255.255.2']:
				ip = ''
			out[project][topo].append({'id': thisport['id'], 
				'from': node, 'to': tmp, 'mac': thisport['mac_address'], 'ip': ip})

	pt = prettytable.PrettyTable(["Project", "Topology", "Node", "Link", "Interface", "MAC Address", "IP Address"])
	pt.align = "l"
	
	for project in out:
		projectname = project
		for topo in out[project]:
			toponame = topo
			out[project][topo].sort(key=itemgetter('from'))
			for port in out[project][topo]:
				pt.add_row([projectname, toponame, port['from'], 
					port['to'], "tap" + port['id'][0:11], port['mac'], port['ip']])
				if len(toponame) > 0:
					toponame = ""
					projectname = ""
	print pt
	return 0


def main():
	project='.*'
	if len(sys.argv) == 2:
		project=str(sys.argv[1]).strip()
	return list_taps(project)


if __name__ == '__main__':
	sys.exit(main())

