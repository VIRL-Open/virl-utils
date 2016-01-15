#!/usr/bin/env python
# vim: tabstop=4 shiftwidth=4 softtabstop=0 noexpandtab

"""
Copyright (c) 2014, Cisco

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

Version 0.2, written 2016-01-15 by rschmied@cisco.com
"""


import xml.etree.ElementTree as ET
import errno, sys


def main():
	ET.register_namespace('', "http://www.cisco.com/VIRL")
	virl_ns = "{http://www.cisco.com/VIRL}"

	if len(sys.argv) == 2:
		with open(str(sys.argv[1]).strip(), "r") as fh:
			root = ET.parse(fh)
	else:
		root = ET.parse(sys.stdin)
	
	nodes = root.findall("{0}node".format(virl_ns))
	for node in nodes:

		# delete all config extensions
		extensions = node.findall("{0}extensions".format(virl_ns))
		for extension in extensions:
			config_elem = extension.find("{0}entry[@key='config']".format(virl_ns))
			if config_elem is not None:
				extension.remove(config_elem)

		# remove all address attributes from interfaces
		# so ANK can start from a clean slate
		interfaces = node.findall("{0}interface".format(virl_ns))
		for attr in [ "ipv4", "ipv6", "netPrefixLenV4", "netPrefixLenV6" ]:
			for interface in interfaces:
				if interface.get(attr) is not None:
					del interface.attrib[attr]

	# write result to stdout
	with sys.stdout as fh:
		try:
			root.write(fh, xml_declaration=True, encoding='UTF-8')
		except IOError, e:
			if e.errno == errno.EPIPE:
				pass
	return 0

if __name__ == '__main__':
	sys.exit(main())

