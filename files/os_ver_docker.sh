#!/bin/bash
if [ $(cat `ls /etc/*{-,_}{release,version} 2>/dev/null` | grep -cE "wheezy") != 0 ]
  then echo unknown_os
elif [ $(cat `ls /etc/*{-,_}{release,version} 2>/dev/null` | grep -cE "(Ubuntu|Debian)") != 0 ]
  then echo deb
elif [ $(cat `ls /etc/*{-,_}{release,version} 2>/dev/null` | grep -c "CentOS release 6.*") != 0 ]
  then echo centos6
elif [ $(cat `ls /etc/*{-,_}{release,version} 2>/dev/null` | grep "CentOS" | grep -c "7.*") != 0 ]
  then echo centos7
else echo unknown_os
fi

