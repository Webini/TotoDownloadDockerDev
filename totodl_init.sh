#!/bin/bash

SECRET_SALT=`head /dev/urandom | tr -dc a-f0-9 | head -c 32`
SECRET_TOKEN=`head /dev/urandom | tr -dc a-f0-9 | head -c 32`
DATABASE_PASS=$1

cat /etc/default/totodl.json |
    sed -e "s/__SECRET_SALT__/$SECRET_SALT/" |
    sed -e "s/__SECRET_TOKEN__/$SECRET_TOKEN/" |
    sed -e "s/__DATABASE_PASSWORD__/$DATABASE_PASS/" > /data/totodl/app/config/config.json

chown totodl. /data/totodl/app/config/config.json

