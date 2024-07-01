

#!/bin/bash

FILE=/home/pi/apps/check/FILE_LOCK

TARGET=192.168.1.15

if [ ! -f $FILE ]; then

ping -W 30 -c 1 $TARGET > /dev/null

if [ $? -ne 0 ]; then

sleep 30

ping -W 30 -c 1 $TARGET > /dev/null

if [ $? -ne 0 ]; then

sleep 30

ping -W 30 -c 1 $TARGET > /dev/null

if [ $? -ne 0 ]; then

sleep 30

ping -W 30 -c 1 $TARGET > /dev/null

if [ $? -ne 0 ]; then

touch $FILE

echo "server is down"

/usr/sbin/sendmail -t < /home/pi/apps/check/message.txt fi fi fi fi fi 
