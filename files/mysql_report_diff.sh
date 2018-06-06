#!/bin/bash
CONTAINER_NAME=$1
PROJECT=$2
SERVER=$3
BACKUP_SERVER=$4
SOURCE_FILE=/backup/check_backup/reports/"$CONTAINER_NAME"_source_db_list.txt
RESULT_FILE=/backup/check_backup/reports/"$CONTAINER_NAME".txt
REPORT_FILE=/backup/check_backup/reports/"$CONTAINER_NAME".report.html
REPORT_BOT_FILE=/backup/check_backup/reports/capybara.log

bad_dblist() {
  printf "<meta charset="utf-8">\n" >> $REPORT_FILE
  echo "<div align="center">" >> $REPORT_FILE
  echo "<h2>Задание: ${PROJECT} ${SERVER}</h2>" >> $REPORT_FILE
  echo "<h3>Docker-контейнер: ${CONTAINER_NAME}</h3>" >> $REPORT_FILE
  echo "<h4>Docker Host: ${BACKUP_SERVER}</h4>" >> $REPORT_FILE
  echo "</div>" >> $REPORT_FILE
  echo "<h3 style=\"color: red;\">${1}</h3>" >> $REPORT_FILE
  echo "<div style=\"text-align: center;overflow: hidden;\">" >> $REPORT_FILE

  echo "<div style=\"float: left; width: 50%;\">" >> $REPORT_FILE
  echo "<h3>Список восстановленных баз данных:</h3>" >> $REPORT_FILE
  cat $RESULT_FILE | awk '{print "<li>"$1" "$2"Mb</li>"}' >> $REPORT_FILE
  echo "</div>" >> $REPORT_FILE

  echo "<div style=\"float: left; width: 50%;\">" >> $REPORT_FILE
  echo "<h3>Исходный список баз данных:</h3>" >> $REPORT_FILE
  cat $SOURCE_FILE | awk '{print "<li>"$1" "$2"Mb</li>"}' >> $REPORT_FILE
  echo "</div>" >> $REPORT_FILE

  #Если нет данных о размере баз, то просто посчитать размер папки
  if [ -z "${SOURCE_DB_SIZE}" ];then
    echo "<h3>Размер восстановленной папки /var/lib/mysql/: $(docker exec -i ${CONTAINER_NAME} du -sch /var/lib/mysql/ | head -n 1 | cut -f 1)</h3>" >> $REPORT_FILE
  fi
  echo "</div>" >> $REPORT_FILE
  exit
}

if [ -f "$SOURCE_FILE" ] && [ -f "$RESULT_FILE" ]; then
  if [ "$(cat $SOURCE_FILE | wc -l )" -eq 0 ]; then
    echo "<h3 style=\"color: red;\">Пустой databaseslist.txt</h3>" >> $REPORT_FILE
  fi

  if [ "$(cat $SOURCE_FILE | wc -l)" -ne "$(cat $RESULT_FILE | wc -l )" ]; then
    bad_dblist "Количество баз различается" >> $REPORT_FILE
  fi

  while read STRING; do
    RESTORE_DATABASE=$(echo ${STRING} | awk '{print $1}')
    RESTORE_DB_SIZE=$(echo ${STRING} | awk '{print $2}' | sed s/[^0-9]//g)
    SOURCE_DB_STRING=$(grep -e "^${RESTORE_DATABASE}[[:blank:]]" -e "^${RESTORE_DATABASE}\$" $SOURCE_FILE)

    #Если база не найдена то алертим и выводим оба списка
    if [ -z "${SOURCE_DB_STRING}" ];then
      bad_dblist "Списки баз данных не совпадают"
    fi

    #Разделяем найденную строку на базу и размер
    SOURCE_DATABASE=$(echo ${SOURCE_DB_STRING} | awk '{print $1}')
    SOURCE_DB_SIZE=$(echo ${SOURCE_DB_STRING} | awk '{print $2}' | sed s/[^0-9]//g)
    # Если есть размер базы данных, то сравниваем размеры
    if [ -n "${SOURCE_DB_SIZE}" ]; then
    #Проверяем что бы не делить на ноль
      if [ "$SOURCE_DB_SIZE" -ne 0 ]; then
        DIFF_PERCENT=$(echo "scale=2; (${RESTORE_DB_SIZE}/${SOURCE_DB_SIZE}*100)-100" | bc | cut -d . -f 1)
      else
        DIFF_PERCENT=0
      fi
      MOD_DIFF_PERCENT=$(echo ${DIFF_PERCENT} | sed 's/-//')
      if [ "$MOD_DIFF_PERCENT" -gt 7 ] && [ "${RESTORE_DATABASE}" != "information_schema" ] && [ "${RESTORE_DATABASE}" != "table_schema" ] && [ "${RESTORE_DATABASE}" != "mysql" ]; then
        echo "<div style=\"text-align: center;overflow: hidden;\">" >> $REPORT_FILE
        bad_dblist "Размер базы  ${RESTORE_DATABASE}: $(echo "scale=2; ${SOURCE_DB_SIZE}" | bc) Mb, размер после восстановления: $(echo "scale=2; ${RESTORE_DB_SIZE}" | bc) Mb, ${MOD_DIFF_PERCENT}%"
      echo "<h2>Задание: ${SERVER_NAME} ${BACKUP_NAME}</h2>" >> $REPORT_FILE
      fi
    fi
  done < $RESULT_FILE

  printf ""$PROJECT" "$SERVER"\n" >> $REPORT_BOT_FILE

else
  bad_dblist "databaseslist не найден" >> $REPORT_FILE
fi
