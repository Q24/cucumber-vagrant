# cucumber-vagrant-dev
The development version of the Vagrant image for Cucumber Tests.

# Installation

1. Checkout the project.
1. (Optional) Make sure [apt-cache](https://github.com/Q24/pani "pani") is running. This will speed things up.
1. Start the vagrant box: `vagrant up`.
1. Make sure you have the Kahuna Acceptance tests checked out in `/opt/hawaii/workspace/kahuna-acc-tests`.

> The box has 'CDPATH' enabled, so if you do a ``cd hawaii-acc<tab>`` you will see this expanded to ``hawaii-acc-core``, if you then press enter, you will go to ``/opt/hawaii/workspace/hawaii-acc-core``.

> ***Note***, the user `vagrant` has `vagrant` as password. 
>
> *(The screen of the cucumber vagrant may lock after a while. :-) )*

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
