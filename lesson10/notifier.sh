#!/bin/bash
# Скрипт парсит файл лога nginx и отправляет на заданный почтовый ящик следующую информацию:
# * Список IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
# * Список запрашиваемых URL (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
# * Ошибки веб-сервера/приложения c момента последнего запуска;
# * Список всех кодов HTTP ответа с указанием их кол-ва с момента последнего запуска скрипта.
# * Скрипт должен предотвращать одновременный запуск нескольких копий, до его завершения.
# * В письме должен быть прописан обрабатываемый временной диапазон.

# --- директория для хранения состояния
conf_dir="$HOME/.otus"
# --- файл блокировки одновременного запуска
lock_file=$conf_dir/notifier.lock
# --- файл для хранения даты-времени прошлого запуска 
prev_file=$conf_dir/prev_date_time

if [ -f "$lock_file" ]; then
  echo "Process running already. Lock file $lock_file exists"
  exit 1
fi

mkdir -p $conf_dir
touch $lock_file
touch $prev_file

# --- файл лога (абс. путь)
log_file=${1:-"access.log"}

# --- начальная дата чтения лога
#     пример: "2023-06-22T00:39:10+0300"
prev_date_time=$2
# --- если дата не задана через аргумент, то читаем ее из файла
if [ -z "$prev_date_time" ]; then
  prev_date_time=$(cat $conf_dir/prev_date_time)
fi
# --- если и в файле дата не указана, то фиксируем значение
if [ -z "$prev_date_time" ]; then
  prev_date_time="1970-01-01"
fi

curr_date_time=$(date --iso-8601=seconds)

# --- номер строки, с которого будем читать лог
line_number=1
# --- читаем файл с заданного номера строки
function catn {
  tail +$line_number $log_file
}

# --- преобразуем дату в timestamp
prev_timestamp=$(date -d "$prev_date_time" +"%s")

# --- читаем лог пока не встретим дату, больше чем начальная
#     при этом увеличиваем счетчик строк
while IFS= read -r log_entry
do
    ((line_number++))

    # --- извлекаем дату из строки журнала
    log_date_time=$(echo $log_entry | egrep '\[.*]' -o | head | tr -d "[]"  | sed 's/\// /g' | sed 's/:/ /')

    # --- преобразуем в timestamp
    log_timestamp=$(date -d "$log_date_time" +"%s")

    # --- сравниваем и если дата в строке больше, то прерываем чтение
    if [ "$log_timestamp" -ge "$prev_timestamp" ]
    then
        break
    fi
done < "$log_file"

echo "LOG REPORT"
echo "-----------------------------------------"
echo "Start date-time:  $prev_date_time"
echo "Finish date-time: $curr_date_time"
echo
echo "Top 10 IPs"
echo "-----------------------------------------"
catn | awk '{print $1}' | uniq -c | sort -nr | head -n 10

echo
echo "Top 8 Requests"
echo "-----------------------------------------"
catn | egrep '(GET|POST)\s/\S?+' -o | sort | uniq -c | sort -nr | head -n 8

echo
echo "Top Requests With Server Errors"
echo "-----------------------------------------"
catn | egrep '(GET|POST).*(HTTP/[0-9].[0-9])" 5[0-9]{2}' -o | sort | uniq -c | sort -nr

echo
echo "HTTP Codes"
echo "-----------------------------------------"
catn | egrep '(GET|POST).*(HTTP/[0-9].[0-9])" [0-9]{3}' -o | awk '{print $4}' | sort | uniq -c | sort -nr

# --- удаляем файл блокировки
rm $lock_file
# --- прописываем новую дату-время в файл
echo $curr_date_time > $prev_file
