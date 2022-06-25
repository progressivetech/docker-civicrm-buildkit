# CiviCRM Buildkit Docker Image #

## Summary ##
Builds a completely self-contained container that runs [CiviCRM Buildkit](https://github.com/civicrm/civicrm-buildkit) via MySQL, Apache, PHP and SSH in a Debian Stretch container. It manages services using runit.

The civicrm-buildkit directory is available on the host and in the container.

## Steps to create ##
Note: this is not a normal Docker file that pulls an image from the Docker network. It's generally not a good idea to pull code blindly from the Internet.

Instead, create your own base image by running these commands AS ROOT (adjust the timezone if you want):

```
temp=$(mktemp -d)
apt-get install debootstrap
export LC_ALL=C && debootstrap --variant=minbase --include=apt-utils,less,iputils-ping,iproute2,vim,locales,libterm-readline-gnu-perl,dnsutils,procps bullseye "$temp" http://http.us.debian.org/debian/

echo "America/New_York" > "$temp/etc/timezone"
chroot "$temp" /usr/sbin/dpkg-reconfigure --frontend noninteractive tzdata
echo "deb http://security.debian.org/ bullseye-security main" > "$temp/etc/apt/sources.list.d/security.list"
echo "deb http://ftp.us.debian.org/debian/ bullseye-updates main" > "$temp/etc/apt/sources.list.d/update.list"
echo "Upgrading"
chroot "$temp" apt-get update
chroot "$temp" apt-get -y dist-upgrade
# Make all servers America/New_York

echo "Importing into docker"
cd "$temp" && tar -c . | docker import - my-bullseye
cd
echo "Removing temp directory"
rm -rf "$temp"
```

For the remaining steps, I assume you are in the directory containing the Dockerfile.

Copy your ssh public key to your current directory:

```
cp ~/.ssh/id_rsa.pub .
```

This file will be copied to the container's authorized_ids file so you can ssh in without a password.

Next, create the directory that will be mounted in the container and hold the buildkit data.

```
mkdir -p civicrm
```

Build the civicrm-buildkit image:

```
docker build -t civicrm-buildkit ./
```

Now, create the container and run it:

```
docker create -v "$(pwd)/civicrm:/var/www/civicrm" -e "DOCKER_UID=$UID" \
  -p 2222:22 -p 8001:8001 --name civicrm-buildkit civicrm-buildkit
docker start civicrm-buildkit
```

You have full access to the civicrm-buildkit directory from the host so you can git pull and push as needed.

## The basic workflow

* ssh into the container (`ssh -p 2222 www-data@localhost`)
* When running for the first time, set things up with: `sudo /usr/local/sbin/civicrm-buildkit-setup`
* run all buildkit commands to create the sites you want:
  * `amp test` 
  * `civibuild create mycivi --type drupal-clean --url http://localhost:8001 --admin-pass admin`
  * Learn [more civibuild commands](https://docs.civicrm.org/dev/en/latest/tools/civibuild/)
* Then, work via your host computer:
  * access your sites via a browser on your host computer (http://localhost:8001).
  * modify code via your editor on your host computer via the civicrm-buildkit directory
   (look in `civicrm-buildkit/build/mycivi`)
  * add git repositories, etc via your host computer

## Maintenance tasks

All maintenance tasks should be run while you are in the container via ssh.

Note: if you destroy or --force create, you will lose any un-committed code modifications and un-pushed git commits. Be sure to commit and push first! After re-creating you will need to add your git repositories all over again.

* Destroy and start over:
  * `civibuild create mycivi --force`
* Or...
  * `civibuild destroy mycivi`
  * `civibuild create mycivi --type drupal-clean --civi-ver master --url http://localhost:8001 --admin-pass admin`
* Update civibuild code:
  * `cd /var/www/civicrm/civicrm-buildkit`
  * `git pull`
  * `civi-download-tools`

## Unit Tests

All tests should be run while you are in the container via ssh.

The testing database will be setup by default. 

Run a test with (for example):

```
cd /var/www/civicrm/civicrm-buildkit/build/mycivi/web/sites/all/modules/civicrm
env CIVICRM_UF=UnitTests phpunit5 ./tests/phpunit/api/v3/CaseTest.php --filter testCaseCreate
```

For more info on testing, see https://docs.civicrm.org/dev/en/latest/testing/phpunit/.

## More info

More [documentation is available via git](https://github.com/civicrm/civicrm-buildkit).


