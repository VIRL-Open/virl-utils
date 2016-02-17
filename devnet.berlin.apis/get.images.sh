curl -s -H \
            "X-Auth-Token: c231cbda51de4a359ab1d6c4fb5ad87c" \
            http://devnet:8774/v2/c36e9fa030194f2cbb47a44332588e60/images \
            | python -m json.tool
