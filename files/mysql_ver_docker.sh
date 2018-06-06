#!/bin/bash
if [ $(mysql -V | grep Maria | wc -l) == 1 ]
then
  echo $(mysql -V | awk '{print $1":"$5}' | awk -F"-" '{print $1}' | sed "s/^\(.*\)\..*$/\1/" | sed s/mysql/mariadb/)
else
  echo $(mysql -V | awk '{print $1":"$5}' | awk -F"-" '{print $1}' | sed "s/^\(.*\)\..*$/\1/")
fi
