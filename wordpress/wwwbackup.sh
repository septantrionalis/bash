#!/bin/sh

DIRECTORY=location_of_backup
if [ -d "$DIRECTORY/www" ]
then
  /usr/bin/ionice -c2 -n7 rsync -rv --delete --no-inc-recursive /var/www $DIRECTORY
fi
