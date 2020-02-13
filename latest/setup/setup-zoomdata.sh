#!/bin/sh

set -e

DEFAULT_TIMEOUT=600

timeout_counter=0

echo "Waiting until Zoomdata start"
until $(curl --output /dev/null --silent --head --fail http://zoomdata-web:8080); do
    sleep 1
    timeout_counter=$((timeout_counter+1))
    if [ $timeout_counter -ge $DEFAULT_TIMEOUT ]; then
        break
    fi
done
echo

if [ $timeout_counter -lt $DEFAULT_TIMEOUT ]; then
    echo "Setting up predefined passwords"
    curl -L -X POST http://zoomdata-web:8080/zoomdata/api/user/initUsers \
        -u "admin:admin" \
        -H "Content-Type: application/vnd.zoomdata.v2+json" \
        -H "Accept: */*" \
        -d '[{"user": "admin", "password": "admin"}, {"user": "supervisor", "password": "supervisor"}]'

    echo "Importing RTS demo dashboard"
    VERSION=$(curl -s zoomdata-web:8080/zoomdata/api/version | jq -r .version)
    echo "  extracted Zoomdata version: ${VERSION}"
    sed -i "s/ZOOMDATA-VERSION-PLACEHOLDER/$VERSION/g" supply-files/rts-dashboard.json
    curl -u "admin:admin" -L -X POST \
        -H "Content-Type: application/vnd.zoomdata.v2+json" \
        -H "Accept: */*" \
        -d @supply-files/rts-dashboard.json \
        http://zoomdata-web:8080/zoomdata/api/dashboards/import

else
    echo "Zoomdata wasn't able to start within $DEFAULT_TIMEOUT seconds. Examine the docker logs."
fi

