#!/usr/bin/env bash

println "Disabling screensaver for user 'vagrant'."

sudo -H -u vagrant bash -c "gsettings set org.gnome.desktop.session idle-delay 3600"
sudo -H -u vagrant bash -c "gsettings set org.gnome.desktop.screensaver idle-activation-enabled false"
sudo -H -u vagrant bash -c "gsettings set org.gnome.desktop.screensaver lock-enabled false"
sudo -H -u vagrant bash -c "gsettings set org.gnome.desktop.screensaver lock-delay 3600"
