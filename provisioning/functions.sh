#!/usr/bin/env bash

files_create() {
  #only if not exists
  mkdir -p ${PUBLIC_FILES}

  chmod 777 ${PUBLIC_FILES}
}

files_delete() {
  # only if exists
  rm -f -r ${PUBLIC_FILES}
}

database_create() {
  # MySQL queries
  QUERIES[0]="CREATE DATABASE IF NOT EXISTS \`${DATABASE}\` DEFAULT CHARSET UTF8 DEFAULT COLLATE utf8_general_ci"
  QUERIES[1]="GRANT ALL ON \`${DATABASE}\`.* TO '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}'"
  QUERIES[2]="GRANT ALL ON \`${DATABASE}\`.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}'"
  QUERIES[3]="GRANT ALL ON \`${DATABASE}\`.* TO '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS}'"

  echo -e "\tCreating MySQL database ${DATABASE}"
  echo -e "\tAdding permissions to ${DATABASE}"

  # Run the queries and assume where user/pass credentials are not entered,
  # the user has a ~/.my.cnf or just an empty password.
  for SQL in  "${QUERIES[@]}"; do
    if [[ -n ${DB_USER} && -n ${DB_PASS} ]]; then
      $MYSQL -u${DB_USER} -p${DB_PASS} -e "${SQL}"
    elif [[ -n ${DB_USER} ]]; then
      $MYSQL -e "${SQL}" -u${DB_USER}
    else
      $MYSQL -e "${SQL}"
    fi
  done
}

# Remove the settings.php if it exists

database_delete() {
  echo -e "\tDeleting database ${DATABASE}"
  echo ${MYSQL} -u${DB_USER} -p${DB_PASS} -e "DROP DATABASE IF EXISTS ${DATABASE}"
  ${MYSQL} -u${DB_USER} -p${DB_PASS} -e "DROP DATABASE IF EXISTS ${DATABASE}"
}

drupal_install() {

  echo -e "\tRunning Drupal installation..."
  cd ${DOCROOT}/sites/default/
  drush site-install standard install_configure_form.update_status_module='array(FALSE,FALSE)' -qy --db-url=mysql://${CREDS}:${CREDS}@${DB_HOST}:${DB_PORT}/${SITENAME} --site-name=${SITENAME} --site-mail=${CREDS}@${SITENAME}.${SUFFIX} --account-name=${CREDS} --account-pass=${CREDS} --account-mail=${CREDS}@${SITENAME}.${SUFFIX}
}
# Change the permissions back to -w
drupal_site_perms() {
 echo -e "\tSetting correct permissions..."
  # Drupal
  chmod go-w ${DOCROOT}/${SITENAME}/sites/default
  chmod go-w ${WEBROOT}/${SITENAME}/sites/default/settings.php
  chmod 777 ${WEBROOT}/${SITENAME}/sites/default/files/
  chmod -R 777 ${WEBROOT}/${SITENAME}/sites/default/files/config_*/active
  chmod -R 777 ${WEBROOT}/${SITENAME}/sites/default/files/config_*/staging
  chown -R ${PERMS} ${WEBROOT}/${SITENAME}
  # drush
  chown ${PERMS} $HOME/.drush/${SITENAME}.aliases.drushrc.php
  chmod 600 $HOME/.drush/${SITENAME}.aliases.drushrc.php

  # Rebuild drush commandfile cache to load the aliases
  drush -q cc drush

  # Rebuilding Drupal caches
  drush -q @${SITENAME}.${SUFFIX} cache-rebuild

  if [[ $(curl -sL -w "%{http_code} %{url_effective}\\n" "http://${SITENAME}.${SUFFIX}" -o /dev/null) ]]; then
    echo -e "${GREEN}Site is available at http://${SITENAME}.${SUFFIX}${COLOR_ENDING}"
  fi
}


