#!/bin/bash
set -e

# Download civicrm buildkit if it's not there.
if [ ! -d /var/www/civicrm/civicrm-buildkit ]; then
  printf "Initializing civicrm-buildkit.\n"
  cd /var/www/civicrm && git clone https://github.com/civicrm/civicrm-buildkit.git buildkit
  cd /var/www/civicrm/buildkit && ./bin/civi-download-tools
  chown -R www-data:www-data /var/www/civicrm
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
    usermod -u "$DOCKER_UID" www-data && chmod -R "$DOCKER_UID" /var/www/civicrm
  fi
fi

if [ "$1" = 'runsvdir' ]; then
  export PATH=/usr/local/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin
  set -- "$@" -P /etc/service
fi

exec "$@"
