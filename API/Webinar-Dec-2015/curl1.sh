#!/bin/bash

HOST="172.16.1.1"

echo curl --user guest:guest http://$HOST:19399/simengine/rest/list
curl --user guest:guest http://$HOST:19399/simengine/rest/list
echo

