#!/usr/bin/env bash

println "Updating sudoers file."

cp sudoers /etc/sudoers
dos2unix -q /etc/sudoers
chmod 0440 /etc/sudoers
