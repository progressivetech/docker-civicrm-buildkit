FROM ptp-base:latest
MAINTAINER Jamie McClelland <jamie@progressivetech.org>
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y \
  php5-mysql \
  php-apc \
  mysql-server \
  mysql-client \
  openssh-server \
  bzip2 \
  libapache2-mod-php5 \
  runit \
  git \
  wget \
  php5-curl \
  nodejs \
  npm 

# Avoid key buffer size warnings and myisam-recover warnings
# See: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=751840
RUN sed -i "s/^key_buffer\s/key_buffer_size\t/g" /etc/mysql/my.cnf
RUN sed -i "s/^myisam-recover\s/myisam-recover-options\t/g" /etc/mysql/my.cnf

# Avoid Apache complaint about server name
RUN sed -i "s/#ServerName www.example.com/ServerName civicrm-buildkit/" /etc/apache2/sites-available/000-default.conf

# Debian installs node as nodejs, other programs want to see it as node
RUN [ ! -h /usr/bin/node ] && ln -s /usr/bin/nodejs /usr/bin/node

# Handle service starting with runit.
RUN mkdir /etc/sv/mysql /etc/sv/apache /etc/sv/sshd
COPY mysql.run /etc/sv/mysql/run
COPY apache.run /etc/sv/apache/run
COPY sshd.run /etc/sv/sshd/run
RUN update-service --add /etc/sv/mysql
RUN update-service --add /etc/sv/apache
RUN update-service --add /etc/sv/sshd

# Give ssh access via key
RUN mkdir /var/www/.ssh
COPY id_rsa.pub /var/www/.ssh/authorized_keys
RUN usermod -s /bin/bash www-data

RUN mkdir /var/www/civicrm

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["runsvdir"]
