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

# PHP variables
PHP="php5-curl"

# Drupal variables
DRUPAL_USER="admin"
DRUPAL_PASSWORD="password"
DRUPAL_SITENAME="d8dev"
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
DRUSH='drush'

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
COLOR_ENDING="\033[0m"

# Different OSs use different paths and vars.
if [[ $UNAME == 'Darwin' ]]; then
  SUFFIX="local"
  if [[ -d /opt/boxen ]]; then
    DB_PORT="13306"
    SUFFIX="dev"
  fi
else
  SUFFIX="local"
fi

# I do things a little differently so adding them in now
if [[ ${HOSTNAME} = 'hades' ]]; then
  DRUSH="$HOME/.composer/vendor/drush/drush/drush"
fi