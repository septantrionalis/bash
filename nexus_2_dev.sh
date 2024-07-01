#!/bin/bash

echo Current params:
echo servicePath=$1
echo serviceName=$2
echo serviceDir=$3

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] ; then
echo
echo Usage: ./script "" "" ""
exit 1
fi

servicePath=$1
serviceName=$2
serviceDir=$3

url="https://tdod.org/service/rest/repository/browse/maven-snapshots/org/tdod/$servicePath/"
rawPathResult=$(curl $url | grep -o '
