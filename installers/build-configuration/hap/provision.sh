#!/bin/bash

internet_connection_check ()
{
    echo "--[QNH]--| Let's check if we have an internet connection..."
    if ( curl -f https://google.com/ >/dev/null 2>&1 )
    then
        echo "--[QNH]--| Internet connection seems to be available."
    else
        echo "--[QNH]--| Could not get access to the internet! Exiting the script!"
        exit 1
    fi
}

access_proxy_connection_check ()
{
    echo "--[QNH]--| Let's check if we have a connection to the Hawaii Access Proxy (https://ap.haw.vodafone.nl)..."
    if ( curl -f -k https://ap.haw.vodafone.nl/ >/dev/null 2>&1 )
    then
        echo "--[QNH]--| Connection to the Hawaii Access Proxy seems to be available."
    else
        echo "--[QNH]--| Could not connect to the Hawaii Access Proxy! Removing the Hawaii Access Proxy setup from the selection menu."
        HAP_AVAILABLE="false"
    fi
}

access_proxy_certificate_check ()
{
	echo "--[QNH]--| Let's check if you already have a certificate directory"
	if [[ -d "${cert_dir}" ]]
	then
		echo "--[QNH]--| I have found the certificate directory '${cert_dir}', so no need to create it."
	else
		echo "--[QNH]--| You don't have a directory '${cert_dir}', I will make one for you now."
		mkdir -p ${cert_dir}
	fi
    echo "--[QNH]--| Let's check if we have the certificate that are required for the Hawaii Access Proxy (https://ap.haw.vodafone.nl)"
    if [[ -f "${cert_dir}/client.cert" ]]
    then
        echo "--[QNH]--| I have found the client.cert file in the directory '${cert_dir}'."
    else
        echo "--[QNH]--| We are missing the client.cert file!"
        MISSING_CERTIIFCATE_FILE="true"
    fi
    if [[ -f "${cert_dir}/client.key" ]]
    then
        echo "--[QNH]--| I have found the client.key file in the directory '${cert_dir}'."
    else
        echo "--[QNH]--| We are missing the client.key file!"
        MISSING_CERTIIFCATE_FILE="true"
    fi

    if [[ ${MISSING_CERTIIFCATE_FILE} == "true" ]]
    then
        echo "--[QNH]--| Could not find one or more of the required certificate files! Removing the Hawaii Access Proxy setup from the selection menu."
        HAP_AVAILABLE="false"
    fi

    if [[ -f "${cert_dir}/client.crt" ]]
    then
        echo "--[QNH]--| I have found the client.crt file in the directory '${cert_dir}'."
    else
        if [[ ${MISSING_CERTIIFCATE_FILE} == "false" ]]
        then
            echo "--[QNH]--| We are missing the client.crt file but I found both the 'client.cert' and 'client.key' files. I will try and merge them into a client.crt file..."
            awk '{print}' "${cert_dir}/client.cert" "${cert_dir}/client.key" > ${cert_dir}/client.crt
            openssl pkcs12 -export -out ${cert_dir}/client.p12 -in ${cert_dir}/client.crt -nodes -passout pass:
            if ( test -f ${cert_dir}/client.crt && openssl x509 -in ${cert_dir}/client.crt -text >/dev/null 2>&1 )
            then
                echo "--[QNH]--| The 'client.cert' and 'client.key' are merged into 'client.crt' successfully."
            else
                echo "--[QNH]--| It seems that the merged file is corrupt. This usually means that the 'client.cert' of 'client.key' are in a wrong format. Please contact QNH DevOps for support..."
                echo "--[QNH]--| I will remove the merged file to make sure no component uses this corrupt file."
                rm -rf ${cert_dir}/client.crt
                echo "--[QNH]--| This there's a problem with the merge I can't proceed. Exiting the script..."
                exit 1
            fi
        fi
    fi
}

function to_int {
    local -i num="10#${1}"
    echo "${num}"
}

check_portnumber ()
{
    local port="$1"
    local -i port_num=$(to_int "${port}" 2>/dev/null)

    if (( ${port_num} < 1 || ${port_num} > 65535 )) ; then
        echo "--[QNH]--| This doesn't seem right. ${tunnelport} can't be used because if failed one of the checks!"
        exit 1
    else
        echo "--[QNH]--| The port number "${tunnelport}" seems to be ok."
    fi
}

set_tunnelport ()
{
    echo "--[QNH]--| Let's setup the SSH tunnel port. This is the port that is used to connect to the Vodafone / Ziggo infrastructure"
    echo "--[QNH]--| when using the SSHgw connection..."
    echo "--[QNH]--| What is the port on your host machine with the SSH tunnel to factory.haw.internal.vodafone.nl:443?"
    echo -n "--[QNH]--| In most cases this is port 6001: [6001] "
    read tunnelport

    echo "--[QNH]--| Let's check if the port you defined is in the allow port range before we proceed..."
    if [[ "${tunnelport}" == "6001" || "${tunnelport}" == "" ]]
    then
        tunnelport=6001
        echo "--[QNH]--| We are going to use the default port ${tunnelport} then."
    else
        check_portnumber ${tunnelport}
    fi

    echo "--[QNH]--| Let's write the port number to the configuration file '/home/vagrant/.hawaii_tunnelport' for future usage and then proceed!"
    echo ${tunnelport} > /home/vagrant/.hawaii_tunnelport
}

set_rinetd_configuration ()
{
    echo "--[QNH]--| Let's check if we need to update the rinetd configuration..."
    if [[ -f "/etc/rinetd.conf" ]]
    then
        echo "--[QNH]--| I found a rinetd configuration file to let's update that with the new gateway tunnel configuration..."
        if [[ ! -z $(grep -i -E "127.0.0.1 ${tunnelport} ${defaultgw_rinetd} ${tunnelport}" "/etc/rinetd.conf") ]]
        then
            echo "--[QNH]--| The required configuration is already in the file so no update is needed."
        else
            echo "--[QNH]--| It seems that we need to update the configuration file."
            sed -i "/# SSH Gateway/a 127.0.0.1 ${tunnelport} ${defaultgw_rinetd} ${tunnelport}" "/etc/rinetd.conf"
            echo "--[QNH]--| Let's restart rinetd."
            sudo service rinetd start
        fi
    else
        echo "--[QNH]--| Could not find a rinetd configuration file so we don't need it."
    fi
}

set_userdetails ()
{
    echo "--[QNH]--| Let's setup the user authentication required to access the various components hosted by Vodafone / Ziggo..."

    while [[ $username == '' ]]
    do
        read -p "--[QNH]--| Enter your Hawaii username [firstname.lastname]: " username
    done
    while [[ $password == '' ]]
    do
        read -s -p "--[QNH]--| Enter your Hawaii password: " password
    done
    echo ""
}

test_git ()
{
    export connection_type=$1

    if [[ ${connection_type} == "sshgw" ]]
    then
        echo "--[QNH]--| Let's test the connection to GIT using the information you gave me..."
        if (curl -f -k -u ${username}:${password} https://localhost:${tunnelport}/git/ >/dev/null 2>&1)
        then
            echo "--[QNH]--| The connection to GIT seems to work."
        else
            echo "--[QNH]--| Something went wrong while testing GIT connection.!"
        fi
    else
        echo "--[QNH]--| Let's test the connection to GIT using the information you gave me..."
        if (wget -qO- --certificate=${cert_dir}/client.cert --private-key=${cert_dir}/client.key --http-user=${username} --http-password=${password} https://ap.haw.vodafone.nl/git/ >/dev/null 2>&1)
        then
            echo "--[QNH]--| The connection to GIT seems to work."
        else
            echo "--[QNH]--| Something went wrong while testing GIT connection.!"
        fi
    fi
}

set_default_gateway ()
{
    echo "--[QNH]--| Let's set the default gateway..."
    defaultgw=`netstat -rn | grep '^0.0.0.0' | awk '{print $2}'`
    defaultgw_rinetd=""

    if [[ $defaultgw =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
    then
      echo "--[QNH]--| Found IP address of your host machine: "$defaultgw
      defaultgw_rinetd=$defaultgw
      cat $sourceconfig | sed -e "s/${gwplaceholder}/${defaultgw}/g" | sed -e "s/${userplaceholder}/${username}/g" | sed -e "s/${passplaceholder}/${password}/g" | sed -e "s/${portplaceholder}/${tunnelport}/g" > $destconfig
      mkdir -p /opt/gradle/init.d
      cat $sourceconfig2 | sed -e "s/${gwplaceholder}/${defaultgw}/g" | sed -e "s/${userplaceholder}/${username}/g" | sed -e "s/${passplaceholder}/${password}/g" | sed -e "s/${portplaceholder}/${tunnelport}/g" > $destconfig2
      # frontend builds are expected to run on the host, so we'll use 127.0.0.1 here as IP address
      defaultgw="127.0.0.1"
      cat $sourceconfig3 | sed -e "s/${gwplaceholder}/${defaultgw}/g" | sed -e "s/${userplaceholder}/${username}/g" | sed -e "s/${passplaceholder}/${password}/g" | sed -e "s/${portplaceholder}/${tunnelport}/g" > $destconfig3
      echo "--[QNH]--| Successfully placed your maven config file here: "$destconfig
      echo "--[QNH]--| Successfully placed your gradle config file here: "$destconfig2
      echo "--[QNH]--| Successfully placed your grunt config file here: "$destconfig3
    else
      echo "--[QNH]--| Could not determine the default gateway (i.e. IP of your host machine). Exiting script now!"
      exit 1
    fi

    set_rinetd_configuration
}

set_default_gateway_hap ()
{
    echo "--[QNH]--| Let's set the default gateway for the Hawaii Access Proxy setup..."
    defaultgw="127.0.0.1"
    tunnelport="8088"
    cat $sourceconfig | sed -e "s/${gwplaceholder}/${defaultgw}/g" | sed -e "s/${userplaceholder}/${username}/g" | sed -e "s/${passplaceholder}/${password}/g" | sed -e "s/${portplaceholder}/${tunnelport}/g" > $destconfig
    mkdir -p /opt/gradle/init.d
    cat $sourceconfig2 | sed -e "s/${gwplaceholder}/${defaultgw}/g" | sed -e "s/${userplaceholder}/${username}/g" | sed -e "s/${passplaceholder}/${password}/g" | sed -e "s/${portplaceholder}/${tunnelport}/g" > $destconfig2
    cat $sourceconfig3 | sed -e "s/${gwplaceholder}/${defaultgw}/g" | sed -e "s/${userplaceholder}/${username}/g" | sed -e "s/${passplaceholder}/${password}/g" | sed -e "s/${portplaceholder}/${tunnelport}/g" > $destconfig3
    echo "--[QNH]--| Configuring any connection that uses Artifactory to connect using the Hawaii Access Proxy setup"
    echo ${tunnelport} > /home/vagrant/.hawaii_tunnelport
}

default_apache_config ()
{
    echo "--[QNH]--| Let's update the Apache HTTPd configuration..."
    cp /installers/apache/apache2.conf /etc/apache2/apache2.conf
    dos2unix -q /etc/apache2/apache2.conf
    chown vagrant:vagrant /etc/apache2/apache2.conf
}

hap_apache_config ()
{
    echo "--[QNH]--| Let's change the Apache HTTPd configuration for Hawaii Access Proxy usage..."
    base64userpass=`echo -n "${username}:${password}" | base64 -w0`

    # update the apache config by adding the devlight config rules
    echo "" >> /etc/apache2/apache2.conf
    echo "# include the Hawaii Access Proxy config file (present in hawaii-dev-setup.git)" >> /etc/apache2/apache2.conf
    echo "SetEnv HAWAII_HAP_CREDENTIALS \"${base64userpass}\"" >> /etc/apache2/apache2.conf
    if [[ -f "/opt/hawaii/workspace/hawaii-config/apache/hap.conf" ]]
    then
        echo "--[QNH]--| Add the hap.conf file from the 'hawaii-config' repository"
        echo "Include \"workspace/hawaii-config/apache/hap.conf\"" >> /etc/apache2/apache2.conf
    elif [[ -f "/opt/hawaii/workspace/hawaii-dev-setup/apache/hap.conf" ]]
    then
        echo "--[QNH]--| Add the hap file from the 'hawaii-dev-setup' repository"
        echo "Include \"workspace/hawaii-dev-setup/apache/hap.conf\"" >> /etc/apache2/apache2.conf
    else
        echo "--[QNH]--| We are missing the required 'hap' files from the 'hawaii-config' or 'hawaii-dev-setup' repository. I can't proceed!"
		echo "--[QNH]--| Please make sure you have branch 'master' pulled to the latest state of repository 'hawaii-config' or 'hawaii-dev-setup'!"
        exit 1
    fi
    echo "--[QNH]--| The Apache HTTPd configuration has been updated."
}

check_certificate_status ()
{
    echo "--[QNH]--| Let's check the certificate file state..."
    if ( test -f ${cert_dir}/client.cert && openssl x509 -in ${cert_dir}/client.cert -text >/dev/null 2>&1 )
    then
        echo "--[QNH]--| The ${cert_dir}/client.cert seems to be a valid certificate file."
    else
        echo "--[QNH]--| The ${cert_dir}/client.cert file seems to be wrong. Exiting script now!"
        exit 1
    fi
    if ( test -f ${cert_dir}/client.key && openssl rsa -in ${cert_dir}/client.key -check >/dev/null 2>&1 )
    then
        echo "--[QNH]--| The ${cert_dir}/client.key seems to be a valid key file."
    else
        echo "--[QNH]--| The ${cert_dir}/client.key file seems to be wrong. Exiting script now!"
        exit 1
    fi

    echo "--[QNH]--| Let's check the certificate status..."
    nofAfter=`openssl x509 -in ${cert_dir}/client.cert -dates | grep notAfter | awk -F= '{print $2}'`
    notBefore=`openssl x509 -in ${cert_dir}/client.cert -dates | grep notBefore | awk -F= '{print $2}'`
    notAfterEpoch=`date -d "${nofAfter}" '+%s'`
    notBeforeEpoch=`date -d "${notBefore}" '+%s'`
    nowEpoch=`date '+%s'`
    checkEpoch=$((nowEpoch+10))
	certcn=`openssl x509 -in ${cert_dir}/client.cert -subject | grep '^subject' | sed -e 's/^subject.*CN=\([^/]*\).*/\1/g'`
    if [ $checkEpoch -lt $notBeforeEpoch -o $checkEpoch -gt $notAfterEpoch ]
    then
        echo "--[QNH]--| Your client certificate has expired or is not yet valid."
        echo "--[QNH]--| Your setup will *NOT* work. Please request a new one from devops.ci@qnh.nl now. Exiting script now!"
        exit 1
    fi

    if [[ $certcn != $username ]]
    then
        echo "--[QNH]--| The common name of your certificate [${certcn}] does not match the provided username [${username}]!"
        echo "--[QNH]--| Your setup will *NOT* work. Please type in the correct username, or request a certificate that"
        echo "           matches your username from devops.ci@qnh.nl now. Exiting script now!"
        exit 1
    fi

    # check if the certificate is bound to expire soon, and print a nice little warning message
    let secsLeft=$notAfterEpoch-$nowEpoch
    if [ $secsLeft -lt 2592000 ]
    then
        daysLeft=`echo "${secsLeft} / 86400" | bc | awk '{print int($1)}'`
        echo "--[QNH]--| WARNING: Your Hawaii Access Proxy client certificate will expire in ${daysLeft} days, you might want to request a new one."
        echo "--[QNH]--| WARNING: Your setup *WILL WORK*, but remember to renew your certificate in time to continue working!"
    fi

    echo "--[QNH]--| The certificate files seem to be correct."
}

create_certificate_private_key ()
{
    echo "--[QNH]--| Let's check if you have a private key already..."
    echo "--[QNH]--| WARNING: Any existing csr (Certificate Signing Request) will be overwritten! Don't proceed if you created a csr before and just haven't received the crt yet!"
    keyfile_valid="true"
    if [[ -f ${cert_dir}/client.key ]]
    then
        echo "--[QNH]--| It seems that you have a private key already. Let's check if the file is valid..."
        if ( test -f ${cert_dir}/client.key && openssl rsa -in ${cert_dir}/client.key -check >/dev/null 2>&1 )
        then
            echo "--[QNH]--| The '${cert_dir}/client.key' seems to be a valid key file."
        else
            echo "--[QNH]--| The '${cert_dir}/client.key' file seems to be wrong."
            keyfile_valid="false"
        fi
        if [[ ${keyfile_valid} == "false" ]]
        then
            read -p "--[QNH]--| Your keyfile seems invalid. You need to remove it before proceeding. Do you wan't me to remove the file for you? " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]
            then
                echo "--[QNH]--| I'm going to remove the file for you!"
                rm -rf ${cert_dir}/client.key
            else
                echo "--[QNH]--| Sins the keyfile seems invalid I can't proceed. Remove the file and restart the procedure! Exiting script now!"
                exit 1
            fi
        fi
    else
        echo "--[QNH]--| It seems that you don't have a keyfile yet. Let's create one..."
        openssl genrsa -out ${cert_dir}/client.key 3096 >/dev/null 2>&1
    fi

    echo "--[QNH]--| I need some information from you before I can create a csr..."
    while [[ $username == '' ]]
    do
        read -p "--[QNH]--| Enter your Hawaii username [firstname.lastname]: " username
    done
    while [[ $email == '' ]]
    do
        read -p "--[QNH]--| Enter your email address: " email
    done
    echo ""

    openssl req -new -key ${cert_dir}/client.key -out ${cert_dir}/client.csr -subj "/emailAddress=$email/C=NL/ST=Limburg/L=Maastricht/O=Vodafone Libertel B.V./OU=Digital/CN=$username" -nodes

    echo "--[QNH]--| Let's check if your csr is valid before we proceed..."

    if ( test -f ${cert_dir}/client.csr && openssl req -in ${cert_dir}/client.csr -noout -text >/dev/null 2>&1 )
    then
        echo "--[QNH]--| The ${cert_dir}/client.csr seems to be a valid signing request file."
    else
        echo "--[QNH]--| The ${cert_dir}/client.csr file seems to be wrong. Exiting script now!"
        exit 1
    fi
}

function upload_csr {
    if [ -e $CERT_FILE ]; then
        read -p "--[QNH]--| The certificate file $CERT_FILE already exists! Do you wish to overwrite? (y/n) " overwrite_cert
        if [ x$overwrite_cert != xy ]; then
            return
        fi
    fi

    while [[ $username == '' ]]; do
        read -p "--[QNH]--| Enter your Hawaii username [firstname.lastname]: " username
    done
    while [[ $password == '' ]]; do
        read -s -p "--[QNH]--| Enter your Hawaii password: " password
    done
    echo ""

    # Temp files
    COOKIE_JAR=$(mktemp)
    PAGE_STORE=$(mktemp)

    # Open main page and follow redirect to login page
    curl --silent --location --cookie-jar ${COOKIE_JAR} ${HAP_URL} > ${PAGE_STORE}

    # Extract URL
    login_url=$(grep '<form id="kc-form-login"' ${PAGE_STORE} | sed -e 's/.*action="\([^"]*\)".*/\1/' | sed -e 's/&amp;/\&/g')
    if [ x$login_url == x ]; then
        echo "--[QNH]--| ERROR: Could not extract URL from HAP login page"
        rm $COOKIE_JAR $PAGE_STORE
        exit 0
   fi

    # Post login
    curl --silent --location --cookie ${COOKIE_JAR} --cookie-jar ${COOKIE_JAR} --data-urlencode "username=${username}" --data-urlencode "password=${password}" "$login_url" > ${PAGE_STORE}

    if grep -q '<form id="kc-totp-login-form"' ${PAGE_STORE}; then
        # Found OTP form, ask user for OTP
        read -p "--[QNH]--| Generate a One-time code using your Google Authenticator app for the non-production hawaii-factory (VodafoneZiggo authentication portal): " otp
        otp_url=$(grep '<form id="kc-totp-login-form"' ${PAGE_STORE} | sed -e 's/.*action="\([^"]*\)".*/\1/' | sed -e 's/&amp;/\&/g')

        # Post OTP
        curl --silent --location --cookie ${COOKIE_JAR} --cookie-jar ${COOKIE_JAR} --data-urlencode "totp=${otp}" ${otp_url} > /dev/null
    else
        echo "--[QNH]--| ERROR: login failed!"
        exit 0
    fi

    # Upload CSR and download result
    if ! curl --silent --cookie ${COOKIE_JAR} -F "csr=@${CERT_CSR_FILE}" ${HAP_URL} > ${PAGE_STORE}; then
        echo "--[QNH]--| ERROR: Failed to upload CSR to HAP for signing"
        rm $COOKIE_JAR $PAGE_STORE
        exit 0
    else
        if ( test -f ${PAGE_STORE} && openssl x509 -in ${PAGE_STORE} -text >/dev/null 2>&1 )
        then
            cp ${PAGE_STORE} ${CERT_FILE}
            MISSING_CERTIIFCATE_FILE="false"
        else
          echo "--[QNH]--| ERROR: Detected invalid security details!"
          exit 0
        fi
    fi

    rm $COOKIE_JAR $PAGE_STORE
}

everything_done ()
{
    echo ""
    echo ""

    echo "--[QNH]--| That seems to be everything! As a final step I will restart Apache HTTPd for you after which you can use the Vagrant..."
    sudo systemctl restart apache2
    echo "--[QNH]--| NOTE: If you have changed your password, don't forget to run the following command in the directory that builds your frontend:"
    echo "                 npm login --registry http://localhost:${tunnelport}/verdaccio/"
    exit 0
}

show_help ()
{
    echo
    echo "--[QNH]--| This command shell will assist you in setting up you local Vagrant environment."
    echo "--[QNH]--| There are a couple of options available to assist you. Below is the list of options and there perpose."
    echo
    echo "--[QNH]--| Option: Hawaii Access Proxy setup"
    if [[ $1 == "hap" ]]
    then
        echo "--[QNH]--|         INFO: This options is currently disabled for you because you don't have the required configuration"
    fi
    echo "--[QNH]--|         This option will assist you in setting up your Vagrant environment to use the Hawaii Access Proxy."
    echo "--[QNH]--| Option: Create certificate private key"
    echo "--[QNH]--|         This option will assist you in creating a private certificate key. This command is used to secure your network connection when using "
    echo "--[QNH]--|         the Hawaii Access Proxy setup. This private key belongs to you as a person and should never be exchanged with any other individual (including QNH DevOps)!"
    echo
}

check_required_repo ()
{
    export repo_check_status_failed="false"

    echo "--[QNH]--| Let's check if you have the required repositories available. Sins this is the 'Kahuna-vagrant' repository we aren't going to check for that one..."
    if [[ ! -f "/opt/hawaii/workspace/hawaii-config/.git/index" && ! -f "/opt/hawaii/workspace/hawaii-dev-setup/.git/index" ]]
    then
        echo "--[QNH]--| We require the 'hawaii-config' or the 'hawaii-dev-setup' repository! We can't proceed without at least one of these!"
        repo_check_status_failed="true"
    else
        echo "--[QNH]--| Found at least one configuration repository."
    fi
    if [[ ! -f "/opt/hawaii/workspace/kahuna-doc/.git/index" ]]
    then
        echo "--[QNH]--| We require the 'kahuna-doc' repository! We can't proceed without this!"
        repo_check_status_failed="true"
    else
        echo "--[QNH]--| I found the 'kahuna-doc' repository."
    fi
    if [[ ! -f "/opt/hawaii/workspace/kahuna-frontend/.git/index" ]]
    then
        echo "--[QNH]--| We require the 'kahuna-frontend' repository! We can't proceed without this!"
        repo_check_status_failed="true"
    else
        echo "--[QNH]--| I found the 'kahuna-frontend' repository."
    fi

    if [[ ${repo_check_status_failed} == "true" ]]
    then
        echo "--[QNH]--| Sins we are missing one (or more) repositories we can't proceed. You will need to checkout the missing repositories first and rerun this script!"
        exit 1
    else
        echo "--[QNH]--| I found all required repositories."
    fi
}

export DIR=/installers/build-configuration

export sourceconfig=${DIR}/maven-sshgw-settings.xml
export destconfig=/opt/apache-maven/conf/settings.xml
export sourceconfig2=${DIR}/artifactory.gradle
export destconfig2=/opt/gradle/init.d/artifactory.gradle

export sourceconfig3=${DIR}/artifactory-settings.json
export destconfig3=/opt/hawaii/workspace/kahuna-frontend/artifactory-settings.json

export gwplaceholder="DEFAULT_GW_IP"
export userplaceholder="USERNAME_PLACEHOLDER"
export passplaceholder="PASSWORD_PLACEHOLDER"
export portplaceholder="PORT_PLACEHOLDER"

export HAP_AVAILABLE="true"
export MISSING_CERTIIFCATE_FILE="false"
export tunnelport=6001
export username=
export password=
export cert_dir="/opt/hawaii/hawaiicert"
export CERT_KEY_FILE=$cert_dir/client.key
export CERT_CSR_FILE=$cert_dir/client.csr
export CERT_FILE=$cert_dir/client.cert
export HAP_URL="https://ap.haw.vodafone.nl/vagrant/connect/"

echo ""
echo ""
echo "  _    _                     _ _                                   _____                     "
echo " | |  | |                   (_|_)     /\                          |  __ \                    "
echo " | |__| | __ ___      ____ _ _ _     /  \   ___ ___ ___  ___ ___  | |__) | __ _____  ___   _ "
echo " |  __  |/ _\ \ \ /\ / / _\ | | |   / /\ \ / __/ __/ _ \/ __/ __| |  ___/ '__/ _ \ \/ / | | |"
echo " | |  | | (_| |\ V  V / (_| | | |  / ____ \ (_| (_|  __/\__ \__ \ | |   | | | (_) >  <| |_| |"
echo " |_|  |_|\__,_| \_/\_/ \__,_|_|_| /_/    \_\___\___\___||___/___/ |_|   |_|  \___/_/\_\\__, |"
echo "                                                                                        __/ |"
echo "                                                                                       |___/"
echo ""
echo ""
echo ""
echo "--[QNH]--| Let's do some checks before we do anything..."
# Check if we have access to the internet
internet_connection_check
# Check if we can reach the Hawaii Access Proxy
access_proxy_connection_check

if [[ ${HAP_AVAILABLE} == "true" ]]
then
    # Check if we have the required certificate files for the Hawaii Access Proxy
    access_proxy_certificate_check
fi

echo ""
echo ""
if [[ ${HAP_AVAILABLE} == "true" ]]
then
    options=("Hawaii Access Proxy setup" "Generate new client certificate for the Hawaii Access Proxy" "Help" "Exit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Hawaii Access Proxy setup")
                echo ""
                echo "--[QNH]--| You chose to use the Hawaii Access Proxy setup"
                check_required_repo
                set_userdetails
                test_git hap
                set_default_gateway_hap
                default_apache_config
                check_certificate_status
                hap_apache_config
                everything_done
                echo ""
                ;;
            "Generate new client certificate for the Hawaii Access Proxy")
                echo ""
                echo "--[QNH]--| You chose to create a (new) client certificate."
                create_certificate_private_key
                upload_csr
                check_certificate_status
                access_proxy_certificate_check
                everything_done
                echo ""
                ;;
            "Help")
                show_help hap
                ;;
            "Exit")
                exit 0
                ;;
            *)
                echo ""
                echo "--[QNH]--| The value '$REPLY' is an invalid option. Please use a valid option!"
                echo "";;
        esac
    done
else
    options=("Generate new client certificate for the Hawaii Access Proxy" "Help" "Exit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Generate new client certificate for the Hawaii Access Proxy")
                echo ""
                echo "--[QNH]--| You chose to create a (new) client certificate."
                create_certificate_private_key
                upload_csr
                check_certificate_status
                access_proxy_certificate_check
                echo ""
                echo "--[QNH]--| The process has been completed successfully. Please re-run this script to start the configuration for the Hawaii Access Proxy setup."
                echo ""
                exit 0
                ;;
            "Help")
                show_help no_hap
                ;;
            "Exit")
                exit 0
                ;;
            *)
                echo ""
                echo "--[QNH]--| The value '$REPLY' is an invalid option. Please use a valid option!"
                echo "";;
        esac
    done
fi
