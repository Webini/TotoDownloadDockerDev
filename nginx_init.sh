#!/bin/bash

SECRET_DOWNLOAD=`head /dev/urandom | tr -dc a-f0-9 | head -c 32`

cat /etc/default/totodl.nginx |
    sed -e "s/__SECRET_DOWNLOAD__/$SECRET_DOWNLOAD/" > /etc/nginx/sites-enabled/totodl

#totodl config
sed -i -e "s/\"download\":\s*\"[a-zA-Z0-9_]*\"/\"download\": \"$SECRET_DOWNLOAD\"/" /data/totodl/app/config/config.json
