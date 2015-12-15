#!/bin/bash

HOST="172.16.1.1"

curl -s -X POST http://$HOST:5000/v2.0/tokens \
            -H "Content-Type: application/json" \
            -d '{"auth": {"tenantName": "admin", "passwordCredentials":
            {"username": "admin", "password": "password"}}}' \
            | python -m json.tool

