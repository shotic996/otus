Практические навыки работы с ZFS.

1.Сcылка на репозиторий GitHub.
2.Bash-скрипт, который будет конфигурировать сервер
3.Файл README.md

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
