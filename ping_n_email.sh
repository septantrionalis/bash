#!/bin/bash

FILE=/home/pi/apps/check/FILE_LOCK
TARGET="192.168.1.15 25"

if [ ! -f $FILE ]; then
  nc -z $TARGET > /dev/null

  if [ $? -ne 0 ]; then
    touch $FILE
    echo "server is down"
    /usr/sbin/sendmail -t < /home/pi/apps/check/message.txt 
  fi 
fi 
