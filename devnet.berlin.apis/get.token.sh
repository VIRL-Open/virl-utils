curl -s -X POST http://devnet:5000/v2.0/tokens \
            -H "Content-Type: application/json" \
            -d '{"auth": {"tenantName": "admin", "passwordCredentials":
            {"username": "admin", "password": "password"}}}' \
            | python -m json.tool
