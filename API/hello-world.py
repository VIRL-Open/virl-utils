#!/usr/bin/env python

import requests

virl_host = "172.16.1.1"
username = password = "guest"
url = "http://%s:19399/simengine/rest/list" % virl_host

result = requests.get(url, auth=(username, password))
print result.text
