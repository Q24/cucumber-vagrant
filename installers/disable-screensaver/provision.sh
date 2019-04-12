#!/usr/bin/env bash

println "Disabling screensaver for user 'vagrant'."

# Try to determine the correct value of DBUS_SESSION_BUS_ADDRESS so we can set Gnome settings via SSH
compatiblePrograms=( nautilus kdeinit kded4 pulseaudio trackerd )

# Attempt to get a program pid
for index in ${compatiblePrograms[@]}; do
    PID=$(pidof -s ${index})
    if [[ "${PID}" != "" ]]; then
        break
    fi
done
if [[ "${PID}" == "" ]]; then
    echo "Could not detect active login session"
    return 1
fi

# Set the environment variable
QUERY_ENVIRON="$(tr '\0' '\n' < /proc/${PID}/environ | grep "DBUS_SESSION_BUS_ADDRESS" | cut -d "=" -f 2-)"
if [[ "${QUERY_ENVIRON}" != "" ]]; then
    export DBUS_SESSION_BUS_ADDRESS="${QUERY_ENVIRON}"
fi

# Disable the screensaver in Gnome
sudo -H -u vagrant bash -c "gsettings set org.gnome.desktop.session idle-delay 0"
sudo -H -u vagrant bash -c "gsettings set org.gnome.desktop.screensaver idle-activation-enabled false"
sudo -H -u vagrant bash -c "gsettings set org.gnome.desktop.screensaver lock-enabled false"
sudo -H -u vagrant bash -c "gsettings set org.gnome.desktop.screensaver lock-delay 0"
