# CiviCRM Buildkit Docker Image #

## Summary ##
Builds a completely self-contained container that runs CiviCRM Buildkit (MySQL, Apache, PHP and SSH).

And, the civicrm-buildkit directory is available on the host and in the container.

The workflow:

 * ssh into the container (ssh -p 222 www-data@localhost)
 * run all buildkit commands to create the sites you want:
  * amp config
   * For MySQL DSN, enter: mysql://root@localhost (no root MySQL password is set)
   * For Permission type, enter 0 (the directories and the web server are both running as www-data)
   * For Apache version, enter apache24
  * amp test
  * civibuild create mycivi --type drupal-clean --civi-ver 4.6 --url http://localhost:8001 --admin-pass admin 

Then, work via your host computer:

 * access your sites via a browser on your host computer (http://localhost:8001).
 * modify code via your editor on your host computer via the civicrm-buildkit directory
 * add git repositories, etc via your host computer

## Steps to use ##

Note: this is not a normal Docker file that pulls an image from the Docker network. It's generally not a good idea to pull code blindly from the Internet.

Instead, create your own base image with these commands:

```
temp=$(mktemp -d)
echo "Running debootstrap"
sudo debootstrap --variant=minbase jessie "$temp" http://mirror.cc.columbia.edu/debian
echo "Importing into docker"
cd "$temp" && sudo tar -c . | docker import - ptp-base
cd
echo "Removing temp directory"
sudo rm -rf "$temp"
```

Before starting, copy your id_rsa.pub file to this directory so you can have ssh access to the container.

This Docker image is intended to be started with:

```
docker build -t civicrm-buildkit ./
mkdir -p civicrm
docker create -v "$(pwd)/civicrm:/var/www/civicrm" -e "DOCKER_UID=$UID" -p 2222:22 -p 8001:8001 --name civicrm-buildkit civicrm-buildkit
docker run civicrm-buildkit
ssh -p 2222 www-data@127.0.0.1
```

You have full access to the civicrm-buildkit directory from the host so you can git pull and push as needed.

