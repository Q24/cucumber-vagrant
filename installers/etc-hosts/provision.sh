#!/bin/bash

println "Setting '/etc/hosts'."
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 hawaii hawaii2
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6 hawaii hawaii2

# Hawaii hostnames
127.0.0.1		kahuna-src.qnh.nl kahuna-target.qnh.nl doc-src.qnh.nl doc-target.qnh.nl kahu-src.qnh.nl kahu-target.qnh.nl
127.0.0.1		guide-src.qnh.nl guide-target.qnh.nl minis-src.qnh.nl minis-target.qnh.nl minis-uc.qnh.nl inbucket.qnh.nl

127.0.0.1   hawaii-cucumber-2
EOF
