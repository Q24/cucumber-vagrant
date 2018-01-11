#!/usr/bin/env bash

println "Installing 'do-install' and 'do-update'."

mkdir -p /home/vagrant/bin
cp /installers/do-install /home/vagrant/bin
cp /installers/disable-apt-proxy /home/vagrant/bin
cp /installers/enable-apt-proxy /home/vagrant/bin
ln -sf /home/vagrant/bin/do-install /home/vagrant/bin/do-update
dos2unix -q /home/vagrant/bin/*
chmod +x /home/vagrant/bin/*

install_bin
