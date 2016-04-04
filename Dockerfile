FROM debian:jessie

VOLUME [ "/data" ]
EXPOSE 22 8042 3306

ENV TOTODL_UID 1000
ENV TOTODL_GID 1000
ENV INITRD No
ENV NGINX_VERSION nginx-1.9.13
ENV OPENSSL_VERSION openssl-1.0.2g
ENV NGINX_VOD_VERSION 1.5.2
ENV DEBCONF_NONINTERACTIVE_SEEN true 
ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root
ENV MYSQL_ROOT_PASSWORD auto
ENV MYSQL_TOTODL_PASSWORD auto

RUN echo "deb http://ftp.fr.debian.org/debian jessie main contrib non-free \n\
          deb-src http://ftp.fr.debian.org/debian jessie main contrib non-free \n\
          deb ftp://ftp.deb-multimedia.org jessie main non-free" >> /etc/apt/sources.list

RUN apt-get update && \
    apt-get -y --force-yes upgrade && \
    apt-get -y --force-yes dist-upgrade && \ 
    apt-get install -y --force-yes apt-utils apt-transport-https curl

#node repo
RUN curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
RUN echo "deb https://deb.nodesource.com/node_5.x jessie main \n\
          deb-src https://deb.nodesource.com/node_5.x jessie main" >> /etc/apt/sources.list && \
          apt-get update

RUN apt-get install -y --force-yes deb-multimedia-keyring \
                                   build-essential \
                                   wget \
                                   transmission-daemon \
                                   ffmpeg \
                                   nodejs \
                                   mysql-server \
                                   supervisor \
                                   sudo \
                                   openssh-server \
                                   python3-guessit \
                                   git \
                                   unzip \
                                   zlib1g-dev \
                                   libpcre3 \
                                   libpcre3-dev \
                                   unzip \
                                   libcurl4-openssl-dev \
                                   libossp-uuid-dev

RUN mkdir -p /home/tmp

#openssl
RUN wget -O /home/tmp/openssl.tar.gz https://www.openssl.org/source/${OPENSSL_VERSION}.tar.gz
RUN tar -xzvf /home/tmp/openssl.tar.gz -C /home/tmp

#nginx vod
RUN wget -O /home/tmp/vod.zip https://github.com/kaltura/nginx-vod-module/archive/${NGINX_VOD_VERSION}.zip
RUN unzip /home/tmp/vod.zip -d /home/tmp

#nginx
RUN wget -O /home/tmp/nginx.tar.gz http://nginx.org/download/${NGINX_VERSION}.tar.gz
RUN tar -xzvf /home/tmp/nginx.tar.gz -C /home/tmp
RUN cd /home/tmp/${NGINX_VERSION} &&  \
    ./configure --with-cc-opt="-O3" \
                --with-http_ssl_module \
                --with-http_secure_link_module \
                --with-threads \
                --with-file-aio \ 
                --with-ipv6 \
                --pid-path=/var/run/nginx.pid \
                --error-log-path=/var/log/nginx/error.log \
                --http-log-path=/var/log/nginx/access.log \
                --with-http_gzip_static_module \
                --with-openssl=/home/tmp/${OPENSSL_VERSION} \ 
                --conf-path=/etc/nginx/nginx.conf \
                --add-module=/home/tmp/nginx-vod-module-${NGINX_VOD_VERSION} && \
    make && \
    make install

COPY config/nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /etc/nginx/sites-enabled

#clean packages
RUN apt-get clean
RUN rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*
RUN rm -rf /home/tmp

#supervisor
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#transmission
COPY config/transmission.json /etc/transmission-daemon/settings.json
RUN chown -R debian-transmission. /etc/transmission-daemon

#mysql
RUN mkdir -p /var/log/mysql/ && \
    mkdir -p /var/run/mysqld && \
    mkdir -p /data/mysql
RUN sed -i -e "s/^datadir\s*=\s*\/var\/lib\/mysql/datadir = \/data\/mysql/" /etc/mysql/my.cnf
RUN cp -p -r /var/lib/mysql /data/mysql

#openssh
RUN echo "root:root" | chpasswd
RUN mkdir -p /var/run/sshd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

#totodl
RUN groupadd -g ${TOTODL_GID} -r totodl && useradd -m -r -u ${TOTODL_UID} -g totodl totodl
RUN npm install -g bower grunt-cli sequelize-cli

#init scripts
COPY mysql_init.sh /etc/mysql_init.sh
COPY totodl_init.sh /etc/totodl_init.sh
COPY nginx_init.sh /etc/nginx_init.sh
COPY config/totodl.json /etc/default/totodl.json
COPY config/totodl.nginx /etc/default/totodl.nginx
RUN chmod +x /etc/mysql_init.sh && \
    chmod +x /etc/totodl_init.sh && \
    chmod +x /etc/nginx_init.sh

COPY init.sh /etc/init.sh
CMD [ "/bin/bash", "/etc/init.sh" ]
