#!/bin/bash

set -e
export DEBIAN_FRONTEND=noninteractive

RESET="\e[0m"
NORMAL="\e[21m\e[39m"
BOLD="\e[1m"
BLUE="\e[94m"
RED="\e[91m"

function blue {
  echo -e "${BLUE}${@}${RESET}"
}
function red {
  echo -e "${RED}${@}${RESET}"
}
function println {
  echo -e "  ${NORMAL}${@}${RESET}"
}

function warn {
  echo "$@" 1>&2
}

# Checking for apt-cacher proxy
DEFAULT_GW=`netstat -rn | grep '^0.0.0.0' | awk '{print $2}'`

if [[ ${DEFAULT_GW} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
  println "Found default gateway: ${DEFAULT_GW}"

	if nc -z "${DEFAULT_GW}" 3142 -w 5; then
		blue "Configuring APT to use apt-cacher proxy"
		println "APT proxy configuration stored in file /etc/apt/apt.conf.d/01proxy"
		echo "Acquire::http::proxy \"http://${DEFAULT_GW}:3142\";" > /etc/apt/apt.conf.d/01proxy
	else
		println "Could not find a local apt-get proxy."
	fi
fi
echo ""

# Start of the actual provisioning script
#sed -i 's/^mesg n/tty -s \&\& mesg n/g' /root/.profile
#source /root/.profile

blue "Installing 'dos2unix'."
apt-get -y update
apt-get -y install dos2unix

blue "Installing installer script for 'vagrant'."
if [ -d /home/vagrant/bin ]
then
  rm -rf /home/vagrant/bin
fi
mkdir -p /home/vagrant/bin
cp /installers/do-install/bin/* /home/vagrant/bin
ln -sf /home/vagrant/bin/do-install /home/vagrant/bin/do-update
dos2unix -q /home/vagrant/bin/*
chmod +x /home/vagrant/bin/*

blue "Installing installer script for 'root'."
mkdir -p /root/bin
ln -sf /home/vagrant/bin/* /root/bin/
echo "PATH=/root/bin:\${PATH}" >> /root/.bashrc
export PATH=/root/bin:${PATH}

# install all software packages using the provisioning script
do-install locale
do-install swap
do-install etc-hosts
do-install apt-software
do-install cachefilesd
do-install hawaii-base-dir
do-install hawaii-env-vars
do-install firefox-esr
do-install sudo
do-install java
do-install maven
do-install apache
do-install help
do-install cc-run
do-install version

# Does not seem to work from SSH.
# do-install disable-screensaver

echo " "
warn '  _____ __  __ _____   ____  _____ _______       _   _ _______ '
warn ' |_   _|  \/  |  __ \ / __ \|  __ \__   __|/\   | \ | |__   __|'
warn '   | | | \  / | |__) | |  | | |__) | | |  /  \  |  \| |  | |'
warn '   | | | |\/| |  ___/| |  | |  _  /  | | / /\ \ | . ` |  | |'
warn '  _| |_| |  | | |    | |__| | | \ \  | |/ ____ \| |\  |  | |'
warn ' |_____|_|  |_|_|     \____/|_|  \_\ |_/_/    \_\_| \_|  |_|'
warn '           _____ _______ _____ ____  _   _   _____  ______ ____  _ _____'
warn '     /\   / ____|__   __|_   _/ __ \| \ | | |  __ \|  ____/ __ \( )  __ \'
warn '    /  \ | |       | |    | || |  | |  \| | | |__) | |__ | |  | |/| |  | |'
warn '   / /\ \| |       | |    | || |  | | . ` | |  _  /|  __|| |  | | | |  | |'
warn '  / ____ \ |____   | |   _| || |__| | |\  | | | \ \| |___| |__| | | |__| |'
warn ' /_/    \_\_____|  |_|  |_____\____/|_| \_| |_|  \_\______\___\_\ |_____/'
warn ' '
warn " "
warn "Before being able to fully use the Vagrant machine, you must do the following:"
warn " "
warn "First of all, make sure you have in your host machine a PIU 2-factor SSL certificate set up."
warn "Normally, you have this in either /opt/hawaii/hawaiicert or C:\AJDT\hawaiicert. If you don't"
warn "generate one by following the PIU Getting Started Guide. Refer to kahuna-vagrant for more info."
warn " "
warn "Next, log in to your machine after this script finishes by typing:"
warn " "
warn " $ vagrant ssh"
warn " "
warn "And then, type:"
warn " "
warn " $ sudo do-update build-configuration/hap"
warn " "
warn "Choose the option for 'Hawaii Access Proxy setup' and follow the instructions."
warn "You must repeat this each time your Hawaii password changes."
warn " "
