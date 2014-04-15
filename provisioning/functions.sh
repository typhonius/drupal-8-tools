#!/usr/bin/env bash

send_message() {
  echo -e "\t$1"
}

setup() {
  # Get the current directory this script is executed from in case we need that.
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

  # Ensure the docroot exists.
  if [[ ! -d ${DOCROOT} ]]; then
    send_message "The directory [${DOCROOT}] does not exist."
    exit 1
  fi

  # Remove the final slash for consistency.
  DOCROOT=${DOCROOT%/}

  # Check we have an index.php and core to become more confident
  # this is a D8 docroot.
  if [[ ! -f ${DOCROOT}/index.php || ! -d ${DOCROOT}/core ]]; then
    send_message "This does not appear to be a Drupal 8 installation."
    exit 1
  fi

  # Assign our public files directory, creating if necessary.
  PUBLIC_FILES=${DOCROOT}/sites/default/files

  if [[ ! -d ${PUBLIC_FILES} ]]; then
    files_create
  fi

  # Assign the database name if the user has provided it.
  if [[ -n $2 ]]; then
    DATABASE=$2
  else
    # If this hasn't been provided, let's use the directory name of the docroot (unless it's docroot)
    if [[ ${DOCROOT##*/} != 'docroot' ]]; then
      DATABASE=${DOCROOT##*/}
    else
      # If the dirname is docroot then cut that off the end and then do the above.
      DBTEMP=${DOCROOT%/docroot}
      DATABASE=${DBTEMP##*/}
    fi
  fi
}

files_create() {
  if [[ ! -d ${PUBLIC_FILES} ]]; then
    send_message "Creating public files directory at ${PUBLIC_FILES}."
    mkdir -p ${PUBLIC_FILES}
    chmod 777 ${PUBLIC_FILES}
  else
    send_message "Public files directory already exists at ${PUBLIC_FILES}."
  fi
}

files_delete() {
  if [[ -d ${PUBLIC_FILES} ]]; then
    echo -e "\tDeleting public files directory at ${PUBLIC_FILES}."
    rm -f -r ${PUBLIC_FILES}
  else
    echo -e "\tPublic files directory not found at ${PUBLIC_FILES}."
  fi
}

database_create() {
  # MySQL queries
  QUERIES[0]="CREATE DATABASE IF NOT EXISTS \`${DATABASE}\` DEFAULT CHARSET UTF8 DEFAULT COLLATE utf8_general_ci"
  QUERIES[1]="GRANT ALL ON \`${DATABASE}\`.* TO '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}'"
  QUERIES[2]="GRANT ALL ON \`${DATABASE}\`.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}'"
  QUERIES[3]="GRANT ALL ON \`${DATABASE}\`.* TO '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS}'"

  send_message "Creating MySQL database ${DATABASE}"
  send_message "Adding permissions to ${DATABASE}"

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
  send_message "Deleting database ${DATABASE}"
  ${MYSQL} -u${DB_USER} -p${DB_PASS} -e "DROP DATABASE IF EXISTS ${DATABASE}"
}

drupal_install() {
  send_message "Installing Drupal"
  cd ${DOCROOT}/sites/default/
  rm ${DOCROOT}/sites/default/settings.php
  cp ${DOCROOT}/sites/default/default.settings.php ${DOCROOT}/sites/default/settings.php
  ${DRUSH} site-install standard install_configure_form.update_status_module='array(FALSE,FALSE)' -qy --db-url=mysql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DATABASE} --site-name=${DRUPAL_SITENAME} --site-mail=${DRUPAL_USER}@${DRUPAL_SITENAME}.${SUFFIX} --account-name=${DRUPAL_USER} --account-pass=${DRUPAL_PASSWORD} --account-mail=${DRUPAL_USER}@${DRUPAL_SITENAME}.${SUFFIX}

}

# Change the permissions back to -w
files_permissions() {
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
  ${DRUSH} -q cc drush

  # Rebuilding Drupal caches
  ${DRUSH} -q @${SITENAME}.${SUFFIX} cache-rebuild

  if [[ $(curl -sL -w "%{http_code} %{url_effective}\\n" "http://${SITENAME}.${SUFFIX}" -o /dev/null) ]]; then
    echo -e "${GREEN}Site is available at http://${SITENAME}.${SUFFIX}${COLOR_ENDING}"
  fi
}


