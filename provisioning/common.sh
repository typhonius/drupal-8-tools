#!/usr/bin/env bash

UNAME=`uname -s`

# Apache variables
WEBROOT="/var/www/html"
#PERMS=`stat -c %U:%G ${WEBROOT}`
SITES_AVAILABLE="/etc/apache2/sites-available"
SITES_ENABLED="/etc/apache2/sites-enabled"
APACHE_22_DEFAULT="default"
APACHE_24_DEFAULT="000-default.conf"
TMP="/tmp"
SUFFIX="local"

# PHP variables
PHP="php5-curl"

# Drupal variables
RELEASE="drupal-8.x-dev"
COMPRESSION="tar.gz"
DRUPAL="${RELEASE}.${COMPRESSION}"

# MySQL variables
MYSQL=`which mysql`

DB_HOST="localhost"
DB_PORT="3306"
DB_USER="root"
DB_PASS=""

# Misc variables
CREDS="root"

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
COLOR_ENDING="\033[0m"

# Different OSs use different paths and vars.
if [[ $UNAME == 'Darwin' ]]; then
  if [[ -d /opt/boxen ]]; then
    echo 'Using mac with boxen'
      DB_PORT="13306"
  fi
else
echo 'Probably using Linux'
fi
