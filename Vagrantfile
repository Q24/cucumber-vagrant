# -*- mode: ruby -*-
# vi: set ft=ruby :
module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def OS.mac?
    (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def OS.unix?
    !OS.windows?
  end

  def OS.linux?
    OS.unix? and not OS.mac?
  end
end


required_plugins = %w(vagrant-vbguest)

plugins_to_install = required_plugins.select {|plugin| not Vagrant.has_plugin? plugin}
if not plugins_to_install.empty?
  puts "Installing plugins: #{plugins_to_install.join(' ')}"
  if system "vagrant plugin install #{plugins_to_install.join(' ')}"
    exec "vagrant #{ARGV.join(' ')}"
  else
    abort "Installation of one or more plugins has failed. Aborting."
  end
end

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  config.vbguest.auto_update = false
  config.vbguest.auto_reboot = true

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "q24/cucumber-test"
  config.vm.box_version = "0.0.1"
  config.vm.hostname = "hawaii-cucumber-2"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  config.vm.box_check_update = false

  config.ssh.password = "vagrant"

  # raise the boot timeout, because slow laptops are slow
  config.vm.boot_timeout = 120

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", type: "dhcp"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  config.vm.synced_folder ".", "/vagrant"
  config.vm.synced_folder "installers", "/installers"

  if OS.windows?
    config.vm.synced_folder "../workspace",
                            "/opt/hawaii/workspace",
                            type: "nfs",
                            mount_options: ["nolock", "fsc"]

  elsif OS.mac?
    osx_version = `uname -r`
    if osx_version >= "17.0.0" && osx_version < "17.3.0"
      puts "macOS High Sierra detected... falling back to rsync... please wait... "
      # high sierra, NFS is dead
      config.vm.synced_folder "../workspace",
                              "/opt/hawaii/workspace",
                              type: "rsync",
                              rsync__exclude: ["node_modules/", "target/", "build/", "log/", "logs/"]

    else
      # low sierra, NFS still sort of works:
      config.vm.synced_folder "../workspace",
                              "/opt/hawaii/workspace",
                              type: "nfs",
                              mount_options: ["nolock", "fsc"]
    end
  elsif OS.linux?
    config.vm.synced_folder "../workspace",
                            "/opt/hawaii/workspace",
                            type: "nfs",
                            mount_options: ["nolock", "fsc"]
  else
    puts "Could not determine host OS or OS not accounted for."
    exit 1
  end

  if File.directory?(File.expand_path("../hawaiicert"))
    config.vm.synced_folder "../hawaiicert", "/opt/hawaii/hawaiicert"
  end

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine.
    vb.gui = true

    # Synchronize the time inside the guest when it drifts for more than 5 seconds.
    vb.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 5000]

    # Customize the amount of memory, default 2G
    if ENV['KAHUNA_CUCUMBER_VAGRANT_MEMORY']
      vb.memory = ENV['KAHUNA_CUCUMBER_VAGRANT_MEMORY']
    else
      vb.memory = "2048"
    end

    # Disable 3d acceleration, causes problems with mouse clicks / screen not available etc etc.
    vb.customize ["modifyvm", :id, "--accelerate3d", "off"]

    vb.cpus = 2
    vb.name = "hawaii-cucumber-2"
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell",
                      privileged: true,
                      path: "provisioning/provision.sh"
end
