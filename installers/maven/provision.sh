#!/bin/bash

println "Installing Maven in /opt."

rm -rf /opt/apache-maven*

FILE=apache-maven-3.5.0.tar.gz
download ${FILE} https://archive.apache.org/dist/maven/maven-3/3.5.0/binaries/apache-maven-3.5.0-bin.tar.gz

echo ${DOWNLOAD_DIR}

tar -xzf ${DOWNLOAD_DIR}/${FILE} --directory /opt
ln -sf /opt/apache-maven-3.5.0 /opt/apache-maven
chown -R vagrant: /opt/apache-maven*

println "Adding 'mvn' to '/usr/local/bin'."
ln -sf /opt/apache-maven/bin/mvn /usr/local/bin
