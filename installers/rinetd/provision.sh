#!/bin/bash

println "Installing rinetd..."

println "Trying to determine the default gateway..."
placeholder="DEFAULT_GW_IP"
defaultgw=`netstat -rn | grep '^0.0.0.0' | awk '{print $2}'`

# install the rinetd config file, generating stuff if necessary
if [[ $defaultgw =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
  println "  Found default gateway: "$defaultgw
  println "  Installing rinetd..."
  sudo apt-get install -y rinetd
  sudo service rinetd stop

  println "  Updating rinetd.conf file with the template file in /installers/rinetd/..."
  cat /installers/rinetd/rinetd.conf | sed "s|${placeholder}|${defaultgw}|g" | sudo tee /etc/rinetd.conf > /dev/null
  sudo dos2unix -q /etc/rinetd.conf

  if [ "${KAHUNA_BACKEND_RUN_MODE}" = "host" ]
  then
    sudo sed -i "s|^#\(.*KAHUNA_BACKEND$\)|\1|g" /etc/rinetd.conf
  else
    sudo sed -i "s|\(^127.*KAHUNA_BACKEND$\)|#\1|g" /etc/rinetd.conf
  fi

  echo "  (Re)-starting rinetd..."
  sudo service rinetd start
else
  echo "  ERROR: Could not determine the default gateway (i.e. IP of your host machine)."
fi
