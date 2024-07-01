#!/bin/bash
# This script is run in cron tab to constantly monitor if the usb drive is mounted.

if [ "$EUID" -ne 0 ]
  then 
  echo "This script needs to be run as root."
  exit
fi

if [ ! -e /media/pi/BACKUP2/README.md ]
then
  echo Mounting USB drive...
  mount -t ext4 -o defaults /dev/sda1 /media/pi/BACKUP2/
else
  echo Already Mounted!
fi
