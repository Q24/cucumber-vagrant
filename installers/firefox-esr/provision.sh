#!/usr/bin/env bash

println "Installing firefox-esr."

export DEBIAN_FRONTEND=noninteractive

sudo add-apt-repository -y ppa:mozillateam/ppa 2>/dev/null
sudo apt-get update
sudo apt-get install firefox-esr
