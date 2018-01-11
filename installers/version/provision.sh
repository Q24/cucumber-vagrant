#!/usr/bin/env bash

install_bin

cp /vagrant/VERSION /etc/kahuna-vagrant-version
dos2unix -q /etc/kahuna-vagrant-version

rm -f /etc/profile.d/check-vagrant-version.sh
echo /home/vagrant/bin/check-vagrant-version > /etc/profile.d/check-vagrant-version.sh
