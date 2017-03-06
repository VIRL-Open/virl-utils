#!/usr/bin/env python
#
# Lists all interfaces of all VMs run by a particular
# project. The project name can be provided as a paramater.
# If none is provided, all projects are listed.
#
# The tap interfaces can then be used to do a traffic
# capture locally using tcpdump
#
# v0.5 18-Feb-2017
# - adjusted to Mitaka
# v0.4 20-Jan-2016
# - added capability to select columns from table
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

import sys
import re
import os
import prettytable
import argparse
from operator import itemgetter

from keystoneauth1 import identity, session
from neutronclient.v2_0 import client


# </guest/endpoint>-<triangle-ghU06c>-<iosv-2>-<guest>
# </guest/endpoint>-<trunk>-<lxc-2>-<iosvl2-1-to-lxc-2>
# </guest/endpoint>-<triangle-ghU06c>-<~mgmt-lxc>-<~lxc-flat>
# </guest/endpoint>-<jjj>-<~mgmt-lxc>-<~lxc-flat>
# </guest/endpoint>-<testAA-u6dRq3>-<lxc-1>-<guest>

def hyphen_range(s):
    """ yield each integer from a complex range string like "1-9,12, 15-20,23"
        http://code.activestate.com/recipes/577279-generate-list-of-numbers-from-hyphenated-and-comma/

    >>> list(hyphen_range('1-9,12, 15-20,23'))
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 15, 16, 17, 18, 19, 20, 23]

    >>> list(hyphen_range('1-9,12, 15-20,2-3-4'))
    Traceback (most recent call last):
        ...
    ValueError: format error in 2-3-4
    """
    for x in s.split(','):
        elem = x.split('-')
        if len(elem) == 1:  # a number
            yield int(elem[0])
        elif len(elem) == 2:  # a range inclusive
            start, end = map(int, elem)
            for i in xrange(start, end + 1):
                yield i
        else:  # more than one hyphen
            raise ValueError('format error in %s' % x)


def list_taps(project, fields):
    out = {}

    auth = identity.Password(auth_url=os.environ['OS_SERVICE_ENDPOINT'],
                             username=os.environ['OS_USERNAME'],
                             password=os.environ['OS_PASSWORD'],
                             project_name=os.environ['OS_PROJECT_NAME'],
                             project_domain_id=os.environ['OS_PROJECT_DOMAIN_ID'],
                             user_domain_id=os.environ['OS_USER_DOMAIN_ID'])
    sess = session.Session(auth=auth)
    nc = client.Client(session=sess)

    prog = re.compile(
        r'</(' + project + ')/endpoint>-<(.*)(?:-\w{6})?>-<(.*)>-<(.*)>')
    ports = nc.list_ports()
    for thisport in ports['ports']:
        m = prog.match(thisport['name'])
        if m:
            project, topo, node, connection = m.group(
                1), m.group(2), m.group(3), m.group(4)
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
                                       'from': node, 'to': tmp, 
                                       'mac': thisport['mac_address'], 
                                       'ip': ip})

    pt = prettytable.PrettyTable(
        ["Project", "Topology", "Node", "Link", "Interface", "MAC Address", "IP Address"])
    pt.align = "l"

    for project in out:
        projectname = project
        for topo in out[project]:
            toponame = topo
            out[project][topo].sort(key=itemgetter('from'))
            for port in out[project][topo]:
                pt.add_row([projectname, toponame,
                            port['from'],
                            port['to'], "tap" + port['id'][0:11],
                            port['mac'],
                            port['ip']])
                if len(toponame) > 0:
                    toponame = ""
                    projectname = ""
        columns = pt.field_names
        if fields:
            columns = []
            for i in list(hyphen_range(fields)):
                columns.append(pt.field_names[i - 1])
    print pt.get_string(fields=columns)
    return 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('project', default='.*', nargs='?',
                        help="project name to list, all projects if ommited")
    parser.add_argument('--columns', '-c',
                        help="list of column numbers to print. like 1,2,4-7")
    args = parser.parse_args()
    return list_taps(args.project, args.columns)


if __name__ == '__main__':
    sys.exit(main())
