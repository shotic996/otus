#!/bin/bash
#Проверяем текущую версию ядра
uname -r
#Подключаем репозиторий для обновления ядра:
sudo yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
#Устанавливаем последнюю версию ядра из репозитория
sudo yum --enablerepo elrepo-kernel install kernel-ml -y
#Обновляем конфигурацию загрузчика
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
#Выбриаем загрузку нового ядра по-умолчанию
sudo grub2-set-default 0
