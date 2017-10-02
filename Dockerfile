FROM my-stretch:latest
MAINTAINER Jamie McClelland <jamie@progressivetech.org>
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y \
  php-mysql \
  php-apcu \
  mysql-server \
  mysql-client \
  openssh-server \
  bzip2 \
  libapache2-mod-php \
  runit \
  git \
  lsb-release \
  acl \
  wget \
  unzip \
  php-cli \
  php-imap \
  php-ldap \
  php-curl \
  php-intl \
  php-gd \
  php-xml \
  php-bcmath \
  php-soap \
  php-zip \
  sudo \
  vim \
  php-mcrypt \
  php-mbstring \
  apache2 \
  ruby \
  gnupg \
  rake \
  bsdmainutils \
  curl

# Now install npm/nodejs
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs


# Avoid Apache complaint about server name
RUN echo "ServerName civicrm-buildkit" > /etc/apache2/conf-available/civicrm-buildkit.conf
RUN a2enconf civicrm-buildkit 

# Drupal requires mod rewrite.
RUN a2enmod rewrite

# We don't want to ever send email. But we also don't want an error when 
# Drupal or CiviCRM tries
RUN ln -s /bin/true /usr/sbin/sendmail

# Handle service starting with runit.
RUN mkdir /etc/sv/mysql /etc/sv/apache /etc/sv/sshd /var/lib/supervise
COPY mysql.run /etc/sv/mysql/run
COPY apache.run /etc/sv/apache/run
COPY sshd.run /etc/sv/sshd/run
RUN update-service --add /etc/sv/mysql
RUN update-service --add /etc/sv/apache
RUN update-service --add /etc/sv/sshd

# Give ssh access via key
RUN mkdir /var/www/.ssh
COPY id_rsa.pub /var/www/.ssh/authorized_keys
COPY id_rsa.pub /root/.ssh/authorized_keys
RUN usermod -s /bin/bash www-data
RUN echo 'export PATH=/var/www/civicrm/civicrm-buildkit/bin:$PATH' > /var/www/.profile

RUN mkdir /var/www/civicrm

# Ensure www-data owns it's home directory so amp will work.
RUN chown -R www-data:www-data /var/www

# Copy setup template file - it will be populated and executed when the
# container is started.
COPY civicrm-buildkit-setup /usr/local/sbin/

# Allow www-data user to restart apache and execute post setup tool.
RUN echo "www-data ALL=NOPASSWD: /usr/bin/sv restart apache, /usr/bin/sv reload apache, /usr/sbin/apache2ctl, /usr/local/sbin/civicrm-buildkit-setup" > /etc/sudoers.d/civicrm-buildkit

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["runsvdir"]
