#!/bin/bash
echo "SELECT table_schema ,sum(data_length+index_length) FROM information_schema.TABLES GROUP BY table_schema;" | docker exec -i $1 mysql --defaults-extra-file=/var/lib/mysql/my.cnf -S /tmp/mysql.sock | awk '{print ""$1" "int(($2)+0.999)""}' | grep -v table_schema > /backup/check_backup/reports/$1.txt
