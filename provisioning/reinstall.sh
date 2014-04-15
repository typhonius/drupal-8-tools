#!/usr/bin/env bash

# This script will reinstall a Drupal installation when given the path to it.
# Most often the usecase for this will be when HEAD breaks irreparably.

# Include all the platform specific variables
. common.sh

# Include the helper functions
. functions.sh

#eventually ./drupal-util reinstall path/to/docroot
function usage {
  echo -e 'Usage: ./reinstall /path/to/docroot [database name]'
  echo -e 'The database used is optional. If one is not used, the directory name of the docroot will be used.'
  exit 0
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ -z $1 || $1 == '-h' || $1 == '--help' ]]; then
  usage
fi

DOCROOT=$1

# Check if dir exists
if [[ ! -d $DOCROOT ]]; then
  echo "The directory [${DOCROOT}] does not exist."
  exit 1
fi

# Remove the final slash for consistency
DOCROOT=${DOCROOT%/}

# Check we have an index.php and core to become more confident
# this is a docroot.
if [[ ! -f ${DOCROOT}/index.php || ! -d ${DOCROOT}/core ]]; then
  echo "This does not appear to be a Drupal 8 installation."
  exit 1
fi

# Assign our public files directory, creating if necessary.
PUBLIC_FILES=${DOCROOT}/sites/default/files
echo -e "Setting the public files directory to ${PUBLIC_FILES}"

if [[ ! -d ${PUBLIC_FILES} ]]; then
  echo "Currently there is no public files location; creating one at ${PUBLIC_FILES}"
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

echo -e "Setting database to ${DATABASE}"

#database_delete
database_create


exit
files_delete

# Delete the database



# Remove the settings.php if it exists



