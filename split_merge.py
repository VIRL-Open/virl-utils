#!/usr/bin/env python

#
# Copyright (c) 2014, Cisco
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
#
# Version 0.2, written 08-06-17
#   added --remove to remove configs from .virl file when extracting
#
# Version 0.1, written 23-12-14 by
# simknigh@cisco.com
#


import sys
import os.path
from argparse import RawTextHelpFormatter

description = """
The order of arguments implies the direction. If the first argument is .virl then it will extract from the first argument into the folder specified by the second.
If the second argument is .virl then it will merge the configs in the first folder into the second argument.
The folder to write into must exist.

By default it will try for a file extension of folder/name.cfg where name is the node name in the .virl file, and folder is the second argument. The default extension is .cfg and can be set using the --extension argument.

When specifying --remove, configurations will be cleared in the .virl file when extracting configurations.

Extracting:
    $ python split_merge.py  project@mixed-A1fWuP.virl cfgs
    Extracting from project@mixed-A1fWuP.virl into cfgs
    Extracted iosv-1 into cfgs/iosv-1.cfg
    Extracted iosxrv-1 into cfgs/iosxrv-1.cfg
    Extracted csr1000v-1 into cfgs/csr1000v-1.cfg
    Extracted nx-osv-1 into cfgs/nx-osv-1.cfg

Merging:
    $ python split_merge.py cfgs project@mixed-A1fWuP.virl
    Merging from cfgs into project@mixed-A1fWuP.virl
    Merged cfgs/iosv-1.cfg into iosv-1
    Merged cfgs/iosxrv-1.cfg into iosxrv-1
    Merged cfgs/csr1000v-1.cfg into csr1000v-1
    Merged cfgs/nx-osv-1.cfg into nx-osv-1
    Wrote updated project@mixed-A1fWuP.virl

Caveats:
- Nested topologies (with sites) may or may not work. They have not been tested.
- The config extensions element must exist for the node in the target .virl file. If necessary these can be created in VM Maestro by putting in a (random) example string into the "configuration" field so that the node config extension is written to the .virl file.
"""

import argparse
parser = argparse.ArgumentParser(
    description=description, formatter_class=RawTextHelpFormatter)
parser.add_argument("source", help="Source to extract or merge from")
parser.add_argument("target", help="Target to extract or merge to")
parser.add_argument(
    "--remove", "-r", dest="remove", help="Remove configs from .virl file", action='store_true')
parser.add_argument(
    "--force", "-f", dest="force", help="Force overwrite of existing config files", action='store_true')
parser.add_argument(
    "--extension", help="Extension to use for config files", default='cfg')
args = parser.parse_args()

argument_a = args.source
argument_b = args.target

# TODO: check argument_a and argument_b exist

# TODO: add option to "force" with -f for clobbering if export file exists
# eg r1.cfg

action = None

force_overwrite = args.force
file_extension = args.extension

if argument_a.endswith(".virl"):
    virl_file, folder_name = argument_a, argument_b
    action = "extract"
    print "Extracting from %s into %s" % (virl_file, folder_name)
elif argument_b.endswith(".virl"):
    virl_file, folder_name = argument_b, argument_a
    action = "merge"
    print "Merging from %s into %s" % (folder_name, virl_file)
else:
    print "Please specify a .virl file",


def main():
    import xml.etree.ElementTree as ET
    root = ET.parse(virl_file)

    ET.register_namespace("virl", "http://www.cisco.com/VIRL")
    virl_ns = "{http://www.cisco.com/VIRL}"

    updated = False
    nodes = root.findall("{0}node".format(virl_ns))
    for node in nodes:
        name = node.get("name")
        node_type = node.get("type")
        if node_type != "SIMPLE":
            print "Skipping non-simple node", name
            continue

        node_cfg_filename = os.path.join(
            folder_name, name) + "." + file_extension
        file_exist = os.path.isfile(node_cfg_filename)

        if action == "merge" and not file_exist:
            print "%s: skipping merge, config file %s doesn't exist" % (name, node_cfg_filename)
            continue
        if action == "extract" and file_exist and not force_overwrite:
            print "%s: skipping extract, file %s already exists. Use -f to force overwrite of existing files" % (name, node_cfg_filename)
            continue

        config_elem = node.find(
            "{0}extensions/{0}entry[@key='config']".format(virl_ns))
        if config_elem is None:
            # TODO: create extension if doesn't exist
            print "%s: skipping, configuration element doesn't exist" % name
            continue

        if action == "merge":
            with open(node_cfg_filename) as fh:
                config_elem.text = fh.read()
            print "Merged %s into %s" % (node_cfg_filename, name)

        if action == "extract" and config_elem.text is not None:
            with open(node_cfg_filename, "w") as fh:
                fh.write(config_elem.text)
            if args.remove:
                config_elem.text = ''
                updated = True
            print "Extracted %s into %s" % (name, node_cfg_filename)

    if action == "merge" or action == "extract" and args.remove and updated:
        root.write(virl_file, xml_declaration=True, encoding='UTF-8')
        print "Wrote updated %s" % virl_file

if __name__ == "__main__":
    main()
