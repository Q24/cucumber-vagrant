#!/bin/bash

DIR=/installers/build-configuration
# settings
sourceconfig=${DIR}/maven-sshgw-settings.xml
destconfig=/opt/apache-maven/conf/settings.xml

sourceconfig2=${DIR}/artifactory.gradle
destconfig2=/opt/gradle/init.d/artifactory.gradle

sourceconfig3=${DIR}/artifactory-settings.json
destconfig3=/opt/hawaii/workspace/kahuna-frontend/artifactory-settings.json

gwplaceholder="DEFAULT_GW_IP"
userplaceholder="USERNAME_PLACEHOLDER"
passplaceholder="PASSWORD_PLACEHOLDER"
portplaceholder="PORT_PLACEHOLDER"

echo ""
echo " __      ________    _____                 "
echo " \ \    / /  ____|  / ____|                "
echo "  \ \  / /| |__    | |     ___  _ __ _ __  "
echo "   \ \/ / |  __|   | |    / _ \| '__| '_ \ "
echo "    \  /  | |      | |___| (_) | |  | |_) |"
echo "     \/   |_|       \_____\___/|_|  | .__/ "
echo "                                    | |    "
echo "                                    |_|    "
echo ""
echo "### IMPORTANT IMPORTANT IMPORTANT ###"
echo "You only must run this script if you are working on a Vodafone"
echo "laptop who is connected to the Vodafone corporate network."
echo ""
echo "Please make sure this is correct. If not, press Ctrl-C now."
echo "Otherwise, press Enter to continue."
echo "### IMPORTANT IMPORTANT IMPORTANT ###"
echo ""
read x

echo "I need some information from you."

username="firstname.lastname"
password="iamawesome"

echo -n "What is your Hawaii username? [firstname.lastname] "
read username
echo ""
echo -n "What is your Hawaii password? [iamawesome] "
read -s password
echo ""

# VF Corporate settings are hardcoded here
tunnelport=80
defaultgw="diggit-vip.vfnl.dc-ratingen.de"

cat $sourceconfig | sed -e "s/${gwplaceholder}/${defaultgw}/g" | sed -e "s/${userplaceholder}/${username}/g" | sed -e "s/${passplaceholder}/${password}/g" | sed -e "s/${portplaceholder}/${tunnelport}/g" > $destconfig
cat $sourceconfig2 | sed -e "s/${gwplaceholder}/${defaultgw}/g" | sed -e "s/${userplaceholder}/${username}/g" | sed -e "s/${passplaceholder}/${password}/g" | sed -e "s/${portplaceholder}/${tunnelport}/g" > $destconfig2
cat $sourceconfig3 | sed -e "s/${gwplaceholder}/${defaultgw}/g" | sed -e "s/${userplaceholder}/${username}/g" | sed -e "s/${passplaceholder}/${password}/g" | sed -e "s/${portplaceholder}/${tunnelport}/g" > $destconfig3
echo "Successfully placed your maven config file here: "$destconfig
echo "Successfully placed your gradle config file here: "$destconfig2
echo "Successfully placed your grunt config file here: "$destconfig3

# Developer light setup
# determine if there is a certificate, and it is an actual certificate file
# in this case, kick off the provisioning of the devlight setup
if [ "${DEV_LIGHT_SETUP}" = "true" ]
then
  if ( test -f /opt/hawaii/hawaiicert/client.crt && openssl x509 -in /opt/hawaii/hawaiicert/client.crt -text >/dev/null 2>&1 )
  then
    echo "I have detected you have a DevLight certificate. I will install the DevLight setup for you. Please hold..."
    # encode the username and password for the apache config
    base64userpass=`echo -n "${username}:${password}" | base64`
    # check if the devlight config has been previously loaded, in which case we will only update the username/password
    if ( grep -q HAWAII_DEVLIGHT_CREDENTIALS /etc/apache2/apache2.conf )
    then
      sudo sed -i -e 's/^SetEnv HAWAII_DEVLIGHT_CREDENTIALS .*$/SetEnv HAWAII_DEVLIGHT_CREDENTIALS \"'${base64userpass}'\"/g' /etc/apache2/apache2.conf
    echo "DevLight setup was already present -- I have only updated your username/password."
    else
      echo "" >> /etc/apache2/apache2.conf
    echo "# include the devlight config file (present in hawaii-dev-setup.git)" >> /etc/apache2/apache2.conf
      echo "SetEnv HAWAII_DEVLIGHT_CREDENTIALS \"${base64userpass}\"" >> /etc/apache2/apache2.conf
      echo "Include \"workspace/hawaii-dev-setup/apache/development-light.conf\"" >> /etc/apache2/apache2.conf
    echo "DevLight setup has been added to your Apache configuration."
    fi

    # since I am such a nice shell script, I will check if the placed DevLight certificate is still valid (or expires soon)...
    nofAfter=`openssl x509 -in /opt/hawaii/hawaiicert/client.crt -dates | grep notAfter | awk -F= '{print $2}'`
    notBefore=`openssl x509 -in /opt/hawaii/hawaiicert/client.crt -dates | grep notBefore | awk -F= '{print $2}'`
    notAfterEpoch=`date -d "${nofAfter}" '+%s'`
    notBeforeEpoch=`date -d "${notBefore}" '+%s'`
    nowEpoch=`date '+%s'`
    if [ $nowEpoch -lt $notBeforeEpoch -o $nowEpoch -gt $notAfterEpoch ]
    then
      echo "WARNING: Your DevLight client certificate has expired or is not yet valid. Please request a new one from devops.ci@qnh.nl now."
    else
      # since the devlight setup seems to be okay, re-update the maven et al configs with the devlight port (for maximum speed)
    defaultgw="127.0.0.1"
    tunnelport="8088"
      cat $sourceconfig | sed -e "s/${gwplaceholder}/${defaultgw}/g" | sed -e "s/${userplaceholder}/${username}/g" | sed -e "s/${passplaceholder}/${password}/g" | sed -e "s/${portplaceholder}/${tunnelport}/g" > $destconfig
      cat $sourceconfig2 | sed -e "s/${gwplaceholder}/${defaultgw}/g" | sed -e "s/${userplaceholder}/${username}/g" | sed -e "s/${passplaceholder}/${password}/g" | sed -e "s/${portplaceholder}/${tunnelport}/g" > $destconfig2
      cat $sourceconfig3 | sed -e "s/${gwplaceholder}/${defaultgw}/g" | sed -e "s/${userplaceholder}/${username}/g" | sed -e "s/${passplaceholder}/${password}/g" | sed -e "s/${portplaceholder}/${tunnelport}/g" > $destconfig3
    echo "NOTE: Since you have a valid DevLight setup, Artifactory will connect over DevLight"

      let secsLeft=$notAfterEpoch-$nowEpoch
    if [ $secsLeft -lt 2592000 ]
    then
      echo "WARNING: Your DevLight client certificate will expire in less than one month, you might want to request a new one from devops.ci@qnh.nl now."
    fi
    fi
    echo "Please wait while I am restarting your Apache..."
    sudo service apache2 restart
  fi
fi
