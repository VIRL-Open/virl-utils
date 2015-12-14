#!/usr/bin/env python
#
# vim: tabstop=4 noexpandtab shiftwidth=4 softtabstop=0
#
# Show all ports of all VM instances for
# all users and topologies.
# Like the console port and the VNC port
#
# v0.2 02-Dec-2015 
# adapted to Kilo release
# v0.1 24-Nov-2014
# initial release
#
# rschmied@cisco.com
#


import os, libvirt, re, prettytable, sys
from novaclient import client
from xml.dom.minidom import parseString

def main():
	# Sample output / field mapping
	# </guest/endpoint>-<Sample_Topologies@single-server-WO9N_h>-<csr1000v-1>
	#		  USER		  PROJECT		   TOPOLOGY			NODE
    # </guest/endpoint>-<kk-gE8P2J>-<server-3>
	prog=re.compile(r'</(.*)/endpoint>-<(.*)-[0-9a-z]+>-<(.*)>', re.IGNORECASE)

	# table=list()
	try:
		libvirt_uri = os.environ['LIBVIRT_DEFAULT_URI']
	except:
		print "LIBVIRT_DEFAULT_URI env not set!"
		print "Using default '" + libvirt_uri + "'"
		libvirt_uri = "qemu:///system"
	conn=libvirt.openReadOnly(libvirt_uri)

	nc=client.Client(2, username=os.environ['OS_USERNAME'], api_key=os.environ['OS_PASSWORD'], 
	project_id=os.environ['OS_TENANT_NAME'], auth_url=os.environ['OS_SERVICE_ENDPOINT'])

	pt = prettytable.PrettyTable(["Project", "Topology", "Node", "VNC", "Console", "Instance Name"])
	pt.align = "l"

	for server in nc.servers.list(search_opts={'all_tenants': True}):
		m=prog.match(server.name)
		if m:
			try:
				domain=conn.lookupByUUIDString(server.id)
			except:
				print "Domain not found / not running"
				return 1
			else:
				doc=parseString(domain.XMLDesc(flags=0))
				# get the VNC port
				port=doc.getElementsByTagName('graphics')[0].getAttribute('port')
				# get the serial console TCP port
				for i in doc.getElementsByTagName('source'):
					if i.parentNode.nodeName == u'console':
						console=i.getAttribute('service')
				# get the instance name
				name=doc.getElementsByTagName('name')[0].childNodes[0].nodeValue
				# add info to table
				pt.add_row([m.group(1), m.group(2), m.group(3), port, console, name])

	print pt.get_string(sortby="Topology")

if __name__ == '__main__':
	sys.exit(main())

