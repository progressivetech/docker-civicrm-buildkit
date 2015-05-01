# CiviCRM Buildkit Docker Image #

Builds a completely self-contained container that runs CiviCRM Buildkit (MySQL, Apache, PHP and SSH).

Before starting, copy your id_rsa.pub file to this directory.

This Docker image is intended to be started with:

```
docker build -t civicrm-buildkit ./
mkdir -p civicrm
docker create -v "$(pwd)/civicrm:/var/www/civicrm" -e "DOCKER_UID=$UID" -p 2222:22 -p 8001:8001 --name civicrm-buildkit civicrm-buildkit
docker run civicrm-buildkit
ssh -p 2222 www-data@127.0.0.1
```

You have full access to the civicrm-buildkit directory from the host so you can git pull and push as needed.

