#!/usr/bin/env python

import requests

virl_host = "172.16.1.1"
username = password = "guest"
url = "http://%s:19399/simengine/rest/launch" % virl_host
topo = open('example.virl', 'r')
headers = {'content-type': 'text/xml'}

result = requests.post(url, auth=(username, password), data=topo, headers=headers)
print result.text
