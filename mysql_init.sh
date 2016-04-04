#!/bin/bash

set -e

ROOT_PASS=$1
CREATE_ROOT_PASS=$2
TOTODL_PASS=$3
CREATE_TOTODL_PASS=$4
sleep 10

#we have to create the root pass
if [[ $CREATE_ROOT_PASS -eq 1 ]]
then
    mysqladmin -u root password $ROOT_PASS
fi

#check if user exists
EXISTS=`echo "SELECT 1 FROM mysql.user WHERE user = 'totodl';" | mysql -u root -p$ROOT_PASS | head -c 1`

if [[ $EXISTS != "1" ]]
then
    echo "CREATE USER 'totodl'@'localhost' IDENTIFIED WITH mysql_native_password;" | mysql -u root -p$ROOT_PASS
    echo "SET PASSWORD FOR 'totodl'@'localhost' = PASSWORD('$TOTODL_PASS'); FLUSH PRIVILEGES;" | mysql -u root -p$ROOT_PASS
    echo "User totodl created"
fi

echo "CREATE DATABASE IF NOT EXISTS totodl; GRANT ALL PRIVILEGES ON totodl.* TO 'totodl'@'localhost';" | mysql -u root -p$ROOT_PASS

echo "Migrate..."
cd /data/totodl/app && sequelize db:migrate --env=database
#create admin user
cd /data/totodl && sudo -u totodl -H node create_user.js
