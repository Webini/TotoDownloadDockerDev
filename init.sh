#!/bin/bash
set -e

if ! [ -e /data/totodl ]
then
    echo "Intializing totodownload..."
    git clone https://github.com/Webini/TotoDownload.git /data/totodl
    mkdir /data/totodl/app/logs
    chown -R totodl. /data/totodl
    cd /data/totodl && \
       sudo -u totodl -H npm install --dev && \
       sudo -u totodl -H bower install && \
       sudo -u totodl -H grunt build && \
       sudo -u totodl -H grunt install
fi

if ! [ -e /data/mysql ]
then
    echo "Initialiazing mysql..."
    cp -r -p /var/lib/mysql /data

    MYSQL_INIT=(${MYSQL_ROOT_PASSWORD} 0 ${MYSQL_TOTODL_PASSWORD} 0)
    if [[ ${MYSQL_ROOT_PASSWORD} == "auto" ]]
    then
        PASS=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16`
        echo "You mysql root password is $PASS"
        MYSQL_INIT[0]=$PASS
        MYSQL_INIT[1]=1
    fi

    if [[ ${MYSQL_TOTODL_PASSWORD} == 'auto' ]]
    then
        PASS=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16`
        echo $PASS > /etc/default/totodl_mysql_pass
        chmod 600 /etc/default/totodl_mysql_pass
        echo "You mysql totodl password is $PASS"
        MYSQL_INIT[2]=$PASS
        MYSQL_INIT[3]=1
    fi

    /etc/mysql_init.sh ${MYSQL_INIT[0]} ${MYSQL_INIT[1]} ${MYSQL_INIT[2]} ${MYSQL_INIT[3]} &
fi

if ! [ -e /data/totodl/app/config/config.json ]
then
    echo "Initializing totodl configuration..."
   
    if [ -e /etc/default/totodl_mysql_pass ]
    then
        /etc/totodl_init.sh `cat /etc/default/totodl_mysql_pass | head -c 1`
    else
        /etc/totodl_init.sh ${MYSQL_TOTODL_PASSWORD}
    fi
fi

if ! [ -e /etc/nginx/sites-enabled/totodl ]
then
    echo "Initializing nginx..."
    /etc/nginx_init.sh
fi

if ! [ -e /data/incomplete ]
then
    echo "Initializing incomplete directory..."
    mkdir /data/incomplete
    chown debian-transmission. /data/incomplete
fi

if ! [ -e /data/downloads ]
then
    echo "Initializing downloads directory..."
    mkdir /data/downloads
    chown debian-transmission:www-data /data/downloads
fi

if ! [ -e /data/transcoded ]
then
    echo "Initializing incomplete directory..."
    mkdir /data/transcoded
    chown totodl:www-data /data/transcoded
fi

exec "/usr/bin/supervisord"
