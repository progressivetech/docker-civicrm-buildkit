#!/bin/bash
set -e

# Download civicrm buildkit if it's not there. This initialization step should only 
# happen the first time you set things up. After than, provided your local civicrm
# directory is intact, it should not be re-created.
if [ ! -d /var/www/civicrm/civicrm-buildkit ]; then
  printf "Initializing civicrm-buildkit.\n"
  cd /var/www/civicrm && git clone https://github.com/civicrm/civicrm-buildkit.git
  cd /var/www/civicrm/civicrm-buildkit && ./bin/civi-download-tools
fi

## Configure amp
sudo -u www-data -H /var/www/civicrm/civicrm-buildkit/bin/amp config:set --mysql_type=dsn --mysql_dsn=mysql://root@localhost --httpd_type=apache24 --perm_type=none

# Ensure that apache is configured to work properly with AMP. We don't do this in the 
# Docker file because then apache will complain if the directory doesn't exist.
mkdir -p /var/www/civicrm/.amp/apache.d
if [ ! -f /etc/apache2/conf-available/amp.conf ]; then 
  echo 'IncludeOptional /var/www/civicrm/.amp/apache.d/*.conf' > /etc/apache2/conf-available/amp.conf
  /usr/sbin/a2enconf amp
fi

# Check for a passed in DOCKER_UID environment variable. If it's there
# then ensure that the www-data user is set to this UID. That way we can
# easily edit files from the host.
if [ -n "$DOCKER_UID" ]; then
  printf "Updating UID...\n"
  # First see if it's already set.
  current_uid=$(getent passwd www-data | cut -d: -f3)
  if [ "$current_uid" -eq "$DOCKER_UID" ]; then
    printf "UIDs already match.\n"
  else
    printf "Updating UID from %s to %s.\n" "$current_uid" "$DOCKER_UID"
    usermod -u "$DOCKER_UID" www-data
  fi
fi

## Ensure that www-data user has permission to all files (eg /var/www/.amp, /var/www/civicrm/civicrm-buildkit/build/)
chown -R www-data:www-data /var/www/

if [ "$1" = 'runsvdir' ]; then
  export PATH=/usr/local/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin
  set -- "$@" -P /etc/service
fi

exec "$@"
