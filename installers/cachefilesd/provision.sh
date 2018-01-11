#!/bin/bash

println "Installing cachefilesd."

apt-get -y install cachefilesd
systemctl start cachefilesd.service
systemctl enable cachefilesd.service
