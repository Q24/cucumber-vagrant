#!/bin/bash

println "Setting up Hawaii development environment variables and hosts entries"

> /home/vagrant/.profile
cat << EOF > /home/vagrant/.profile
if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

source /home/vagrant/.welcome

# CD Path
export CDPATH=.:/opt/hawaii/workspace/
alias cd='>/dev/null cd'

export PATH=~/bin:${PATH}:/opt/maven/bin
EOF

chown vagrant:vagrant /home/vagrant/.profile

cp welcome /home/vagrant/.welcome
echo ""
