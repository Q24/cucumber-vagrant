#!/bin/bash
echo "Installing Apache HTTP server"
apt-get -y install apache2 apache2-bin pkg-config apache2-dev libnghttp2-14
service apache2 stop 2> /dev/null

APACHE_DIR=/opt/hawaii/apache24
rm -rf ${APACHE_DIR}
mkdir -p ${APACHE_DIR}/logs ${APACHE_DIR}/conf ${APACHE_DIR}/htdocs

ln -sf  /usr/lib/apache2/modules ${APACHE_DIR}/modules
cp mime.types ${APACHE_DIR}/conf/mime.types
chown -R vagrant:vagrant ${APACHE_DIR}

# Copy index.html page (and content)
cp index.html ${APACHE_DIR}/htdocs/index.html
cp favicon.ico ${APACHE_DIR}/htdocs/favicon.ico
cp index_styles.css ${APACHE_DIR}/htdocs/index_styles.css

# copy the configuration files to /etc/apache2
cp development.conf /etc/apache2/development.conf
cp apache2.conf /etc/apache2/apache2.conf
chown vagrant:vagrant /etc/apache2/apache2.conf /etc/apache2/development.conf

cp mod_http2.so /usr/lib/apache2/modules/mod_http2.so
chmod 644 /usr/lib/apache2/modules/mod_http2.so

sed -i -e "s#export APACHE_PID_FILE.*\$#export APACHE_PID_FILE=${APACHE_DIR}/apache.pid#g" /etc/apache2/envvars

cp bin/* ~vagrant/bin
chmod +x ~vagrant/bin/*
chown -R vagrant: ~vagrant/bin

service apache2 start
