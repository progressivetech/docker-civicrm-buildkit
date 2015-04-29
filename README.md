# CiviCRM Buildkit Docker Image #

This Docker image is intended to be started with:

```
mkdir -p civicrm-buildkit
docker run -v ./civicrm-buildkit:/var/www/civicrm/civicrm-buildkit -e "DOCKER_UID=$UID" -t civicrm-buildkit ./
```
