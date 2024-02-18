Практические навыки работы с ZFS.

1.Сcылка на репозиторий GitHub.
2.Bash-скрипт, который будет конфигурировать сервер
3.Файл README.md

#Задание 1.
#Скачиваем ZFS
yum install -y  yum-utils
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install -y https://zfsonlinux.org/epel/zfs-release-2-3$(rpm --eval "%{dist}").noarch.rpm
yum install -y zfs
/sbin/modprobe zfs

#Создаём 4-пулла из двух дисков в режиме RAID 1
zpool create otus1 mirror /dev/sdb /dev/sdc
zpool create otus2 mirror /dev/sdd /dev/sde
zpool create otus3 mirror /dev/sdf /dev/sdg
zpool create otus4 mirror /dev/sdh /dev/sdi


#Добавим алгоритмы сжатия
zfs set compression=lzjb otus1
zfs set compression=lz4 otus2
zfs set compression=gzip-9 otus3
zfs set compression=zle otus4

Посмотреть все настройки пула
zfs get all otus1

#Задание 2. Определение настроек пула

#Скачали архив и разархивировали:
wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download'
tar -xzvf archive.tar.gz

#Проверили возможность импорта
zpool import -d zpoolexport/

#Провели импорт с новым именем пула
zpool import -d zpoolexport/ otus newotus


#Просмотр требуемых настроек
#Размер хранилища
[root@localhost lesson5]# zfs get available newotus
NAME     PROPERTY   VALUE  SOURCE
newotus  available  350M   -

#Тип пула
[root@localhost lesson5]# zfs get type newotus
NAME     PROPERTY  VALUE       SOURCE
newotus  type      filesystem  -

#Значение recordsize
[root@localhost lesson5]# zfs get recordsize newotus
NAME     PROPERTY    VALUE    SOURCE
newotus  recordsize  128K     local

#Метод сжатия
[root@localhost lesson5]# zfs get compression newotus
NAME     PROPERTY     VALUE           SOURCE
newotus  compression  zle             local


#Задание № 3. Работа со снапшотом
#Восстановим файловую систему из снапшота:
zfs receive newotus/test@today < otus_task2.file

#Ищем файл и читаем его содержимое:
[root@localhost lesson5]# find /newotus/test/ -name "secret_message"
/newotus/test/task1/file_mess/secret_message
[root@localhost lesson5]# cat /newotus/test/task1/file_mess/secret_message
https://otus.ru/lessons/linux-hl/
