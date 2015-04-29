FROM ptp-base:latest
MAINTAINER Jamie McClelland <jamie@progressivetech.org>
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y \
  php5-mysql \
  php-apc \
  mysql-server \
  mysql-client \
  libapache2-mod-php5 \
  runit \
  git \
  nodejs

# Avoid key buffer size warnings and myisam-recover warnings
# See: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=751840
RUN sed -i "s/^key_buffer\s/key_buffer_size\t/g" /etc/mysql/my.cnf
RUN sed -i "s/^myisam-recover\s/myisam-recover-options\t/g" /etc/mysql/my.cnf

# Handle service starting with runit.
RUN mkdir /etc/sv/mysql /etc/sv/apache /etc/sv/apache
COPY mysql.run /etc/sv/mysql/run
COPY apache.run /etc/sv/apache/run
COPY sshd.run /etc/sv/ssh/run
RUN update-service --add /etc/sv/mysql
RUN update-service --add /etc/sv/apache
RUN update-service --add /etc/sv/ssh

# Install civicrm-buildkit
RUN mkdir /var/www/civicrm

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD runsvdir
