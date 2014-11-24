#!/usr/bin/env python
#
# Lists all interfaces of all VMs run by a particular
# user. The username has to provided as a paramater.
# The tap interfaces can then be used to do a traffic
# capture locally using tcpdump
#
# rschmied@cisco.com
#

import sys, re, os, prettytable
from neutronclient.v2_0 import client
from operator import itemgetter


"""

In [14]: m.group(0)
Out[14]: '</guest/endpoint>-<Sample_Project@asa-test-topo-yJHnoK>-<iosv-2>-<Multipoint Connection-1>'

In [15]: m.group(1)
Out[15]: '/guest/endpoint'

In [16]: m.group(2)
Out[16]: 'Sample_Project'

In [16]: m.group(3)
Out[16]: 'asa-test-topo'

In [17]: m.group(4)
Out[17]: 'iosv-2'

In [18]: m.group(5)
Out[18]: 'Multipoint Connection-1'

will not match jumphost ports!
not interested in these, anyway

"""


def list_taps(user):
	out = {}
	nc = client.Client(username=os.environ['OS_USERNAME'], password=os.environ['OS_PASSWORD'], 
		tenant_name=os.environ['OS_TENANT_NAME'], auth_url=os.environ['OS_AUTH_URL'])
	prog = re.compile(r'</(' + user + '/endpoint)>-<(.*)@(.*)-[0-9a-zA-Z_]{6}>-<(.*)>-<(.*)>')
	ports = nc.list_ports()
	for thisport in ports['ports']:
		m = prog.match(thisport['name'])
		if m:
			proj = m.group(2)
			topo = m.group(3)
			if not proj in out:
				out[proj] = {}
			if not topo in out[proj]:
				out[proj][topo] = []
			if m.group(5) == user:
				tmp = 'Management Network'
			else:
				tmp = m.group(5)
			out[proj][topo].append({'id': thisport['id'], 
				'from': m.group(4), 'to': tmp})

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

def main():
	if len(sys.argv) != 2:
		sys.stdout.write(str(sys.argv[0]))
		print ": username needed as argument! bailing out"
		return 1		
	else:
		list_taps(str(sys.argv[1]).strip())
		return 0


if __name__ == '__main__':
	sys.exit(main())


