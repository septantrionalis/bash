#!/bin/bash

# Replace the hexadecimal value at the offset (first number) with the specified value (the second number) at the specified file.
FILE=DARK01.SAV    
if [ -f $FILE ]; then
  ./set-byte.py $FILE 0x39FB 0xff
else
  echo $FILE not found!
fi

FILE=DARK02.SAV
if [ -f $FILE ]; then
  ./set-byte.py $FILE 0x39FC 0xff
else
  echo $FILE not found!
fi

FILE=DARK03.SAV
if [ -f $FILE ]; then
  ./set-byte.py $FILE 0x39FD 0xff
else
  echo $FILE not found!
fi
