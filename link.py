#!/usr/bin/env python
#
# Control the vNIC in a libvirt VM instance.
# Provide the MAC address and "up" or "down".
# If the MAC is found in the system and belonging
# to a VM, the port will be either "shut" (down)
# or "no shut" (up).
#
# v0.3 18-Feb-2017
# adjusted to Mitaka
# v0.2 02-Dec-2015
# adapted to Kilo release
# v0.1 24-Nov-2014
# initial release
#
# rschmied@cisco.com
#

import os
import libvirt
import re
import prettytable
import sys
import xml.dom.minidom
from keystoneauth1 import identity, session
from neutronclient.v2_0 import client
from xml.dom.minidom import parseString


def normalize_mac(mac):
    nm = re.sub('[.:-]', '', mac).lower()
    nm = ":".join(["%s" % nm[i:i + 2] for i in range(0, 12, 2)])
    return nm


def set_link_state(nicXML, state):
    try:
        element = nicXML.getElementsByTagName('link')[0]
    except IndexError:
        element = xml.dom.minidom.Element('link')
        element.setAttribute('state', state)
        nicXML.appendChild(element)
    else:
        element.setAttribute('state', state)


def link(mac, state):
    try:
        libvirt_uri = os.environ['LIBVIRT_DEFAULT_URI']
    except:
        libvirt_uri = "qemu:///system"
        print "LIBVIRT_DEFAULT_URI env not set!"
        print "Using default '" + libvirt_uri + "'"

    auth = identity.Password(auth_url=os.environ['OS_SERVICE_ENDPOINT'],
                             username=os.environ['OS_USERNAME'],
                             password=os.environ['OS_PASSWORD'],
                             project_name=os.environ['OS_PROJECT_NAME'],
                             project_domain_id=os.environ[
                                 'OS_PROJECT_DOMAIN_ID'],
                             user_domain_id=os.environ['OS_USER_DOMAIN_ID'])
    sess = session.Session(auth=auth)
    nc = client.Client(session=sess)

    ports = nc.list_ports()
    conn = libvirt.open(libvirt_uri)

    for thisport in ports['ports']:
        if thisport['mac_address'] == mac:
            print "Node Name for MAC '" + mac + "': \n" + thisport['name']
            try:
                domain = conn.lookupByUUIDString(thisport['device_id'])
            except:
                print "Domain not found! Maybe MAC belongs to a system port?"
                sys.exit(1)
            print "Domain Name: '" + domain.name() + "'"
            domXML = parseString(domain.XMLDesc(flags=0))
            interfaces = domXML.getElementsByTagName('interface')
            for nicXML in interfaces:
                this = nicXML.getElementsByTagName('mac')[0]
                if this.attributes['address'].value == mac:
                    set_link_state(nicXML, state)
                    nicStrXML = nicXML.toprettyxml(encoding='utf-8')
                    try:
                        domain.updateDeviceFlags(nicStrXML,
                                                 libvirt.VIR_DOMAIN_AFFECT_LIVE)
                    except:
                        print "Could not update interface!"
                    else:
                        print "Interface updated!"
                    return
    print "MAC address '" + mac + "' not found on system!"


def main():
    if len(sys.argv) != 3:
        print sys.argv[0] + " usage: MAC-address up|down "
        print "aborting!"
        sys.exit(1)
    else:
        mac = normalize_mac(sys.argv[1].strip())
        state = sys.argv[2].strip()
        if not state in ['up', 'down']:
            print "up or down expected!"
            sys.exit(1)
        link(mac, state)


if __name__ == '__main__':
    main()
