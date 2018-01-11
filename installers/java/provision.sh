#!/bin/bash

println "Installing Java 8"
add-apt-repository -y ppa:webupd8team/java 2> /dev/null
apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections

mkdir -p /var/cache/oracle-jdk8-installer
cp wgetrc /var/cache/oracle-jdk8-installer/

# Temporary workaround because the 8u144 download have been removed from java.oracle.com and the PPA package is not yet updated.
# As soon as the package for version 8u152 is fixed, this can be removed and reverted to the old version as below.

#disable-apt-proxy
#apt-get -y install oracle-java8-installer oracle-java8-set-default oracle-java8-unlimited-jce-policy || true
#cd /var/lib/dpkg/info
#sed -i 's|JAVA_VERSION=8u144|JAVA_VERSION=8u152|' oracle-java8-installer.*
#sed -i 's|PARTNER_URL=http://download.oracle.com/otn-pub/java/jdk/8u144-b01/090f390dda5b47b9b721c7dfaa008135/|PARTNER_URL=http://download.oracle.com/otn-pub/java/jdk/8u152-b16/aa0333dd3019491ca4f6ddbe78cdb6d0/|' oracle-java8-installer.*
#sed -i 's|SHA256SUM_TGZ="e8a341ce566f32c3d06f6d0f0eeea9a0f434f538d22af949ae58bc86f2eeaae4"|SHA256SUM_TGZ="218b3b340c3f6d05d940b817d0270dfe0cfd657a636bad074dcabe0c111961bf"|' oracle-java8-installer.*
#sed -i 's|J_DIR=jdk1.8.0_144|J_DIR=jdk1.8.0_152|' oracle-java8-installer.*
#apt-get -y install oracle-java8-installer oracle-java8-set-default oracle-java8-unlimited-jce-policy
#enable-apt-proxy

# This is the regular way to install java

apt-get -y install oracle-java8-installer oracle-java8-set-default
disable-apt-proxy
apt-get -y install oracle-java8-unlimited-jce-policy
enable-apt-proxy
