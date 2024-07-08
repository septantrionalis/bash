#!/bin/bash

# replace the first hex value with the second on the specified file.
./set-byte.py DARK01.SAV 0x39FB 0xff
./set-byte.py DARK01.SAV 0x39FC 0xff
./set-byte.py DARK01.SAV 0x39FD 0xff
