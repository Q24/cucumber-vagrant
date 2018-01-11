#!/usr/bin/env bash

println "Creating a 4GB swap file"
dd if=/dev/zero of=/swapfile.swp bs=1024 count=4194304 2> /dev/null

mkswap /swapfile.swp
chmod 600 /swapfile.swp
echo "/swapfile.swp swap swap defaults 0 0" >> /etc/fstab
swapon -a
echo ""
