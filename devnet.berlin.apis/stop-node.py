#!/usr/bin/env python

# Import the required libraries, most notably for our 
# purposes 'requests' and 'logging'

import os, requests, sys, logging

# Enable debugging in httplib so we see the request and response headers

try:
    import http.client as http_client
except ImportError:
    import httplib as http_client

http_client.HTTPConnection.debuglevel = 1

# Initialize the logging function data structures

logging.basicConfig() 
logging.getLogger().setLevel(logging.DEBUG)
requests_log = logging.getLogger("requests.packages.urllib3")
requests_log.setLevel(logging.DEBUG)
requests_log.propagate = True

# Define our function to stop one or all nodes in the simulation

def stop_node(simulation, node):
    virl_host = "devnet"
    username  = password = "guest"
    url       = "http://%s:19399/simengine/rest/update/%s/stop" % (virl_host, simulation)
    headers   = {'content-type': 'text/xml'}
    payload   = {'nodes': node}


    result = requests.put(url, auth=(username, password), params=payload, headers=headers) 

def main():
        if len(sys.argv) != 3:
                sys.stdout.write(str(sys.argv[0]))
                print ":  usage: stop-node.py <simulation-name> <node-name>"
                return 1                
        else:
                stop_node(str(sys.argv[1]).strip(),str(sys.argv[2]).strip())
                return 0


if __name__ == '__main__':
        sys.exit(main())
