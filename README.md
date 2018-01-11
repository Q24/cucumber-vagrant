# cucumber-vagrant-dev
The development version of the Vagrant image for Cucumber Tests.

# Installation

1. Checkout the project in `/opt/hawaii`.
1. (Optional) Make sure [apt-cache](https://github.com/Q24/pani "pani") is running. This will speed things up.
1. (Optional) Make sure you have the Kahuna Acceptance tests checked out in `/opt/hawaii/workspace/kahuna-acc-tests`.
1. Start the vagrant box: `vagrant up`.
1. Disable screensaver, *inside* vagrant do `sudo do-update disable-screensaver`    
1. Install Virtual Box Guest Additions: `vagrant vbguest --do install`
1. Restart the vagrant box: `vagrant halt && vagrant up`

## Troubleshooting the installation
#### No guest IP was given to the Vagrant core NFS helper
If you encounter something like:
> ```
> You may need to restart the Window System (or just restart the guest system)
> to enable the Guest Additions.
> 
> An error occurred during installation of VirtualBox Guest Additions 5.1.30. Some functionality may not work as intended.
> In most cases it is OK that the "Window System drivers" installation failed.
> Job for vboxadd-service.service failed because the control process exited with error code. See "systemctl status vboxadd-service.service" and "journalctl -xe" for details.
> Unmounting Virtualbox Guest Additions ISO from: /mnt
> ==> default: Checking for guest additions in VM...
> ==> default: Setting hostname...
> ==> default: Configuring and enabling network interfaces...
> No guest IP was given to the Vagrant core NFS helper. This is an
> internal error that should be reported as a bug.
> ```
Cause: you have most likely updated Virtual Box. After an update of Virtual Box, the guest additions will be updated. Updating the guest additions may cause the NFS mount to fail.

Remedy:
```$bash
$ vagrant halt
$ vagrant up
```

#### The screen is locked.
The vagrant box will lock it's screen after a period of inactivity.
You can log in again with the password `vagrant`.

#### I cannot log in
The user `vagrant` has `vagrant` as password. 

# Notes 

> The box has 'CDPATH' enabled, so if you do a ``cd hawaii-acc<tab>`` you will see this expanded to ``hawaii-acc-core``, if you then press enter, you will go to ``/opt/hawaii/workspace/hawaii-acc-core``.

# Running Tests
Use `cc-run [suite]` to run a test. For this, open a terminal from the vagrant box.
Simply open a terminal, do:
```bash
$ cc-run CucumberSmokeIT
```

Running a single test, add ``@temporary`` to the feature file and:
```
$ run-cc CucumberTempIT
```

Sit back and drink some coffee.
