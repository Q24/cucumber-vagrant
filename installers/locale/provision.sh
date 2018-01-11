#!/bin/bash

println "Setting system locale"

cp locale /etc/default/locale
locale-gen en_US.UTF-8
timedatectl set-timezone Europe/Amsterdam
