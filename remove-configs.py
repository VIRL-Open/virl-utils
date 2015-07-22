#!/usr/bin/env python

from __future__ import print_function
from lxml import etree as ElementTree
import sys

def walk(root, depth):
	# print('\t'*depth, "tag=", root.tag, "keys=", root.keys(), sep='')
	for child in root:
		if len(child) > 0:
			walk(child, depth+1)
		else:
			# print('\t'*(depth+1), end='')
			# print(child.tag, child.keys())
			if child.tag.lower().endswith('entry') and \
			   child.getparent().tag.lower().endswith('extensions'):
				(k, v)=child.keys()
				# print(k,v)
				# print(child.get(k),child.get(v))
				if child.get(k).lower() == 'string' and \
				   child.get(v).lower() == 'config':
					#print(child.text)
					child.text = ""
	# print('\t'*depth, "#", sep='')

root = ElementTree.parse(sys.stdin).getroot()
walk(root,0)
ElementTree.dump(root)

