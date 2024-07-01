#!/bin/sh

DIRECTORY=/directory_where_backup_will_go
if [ -d "$DIRECTORY" ]
then
  filename=$(date +%Y%m%d_%H%M%S).sql
  mysqldump --all-databases -u root --password='insertpasswordhere' > $DIRECTORY$filename
  cd $DIRECTORY
  tar czvf $filename.tgz $filename
  rm $filename 
fi
exit $?
