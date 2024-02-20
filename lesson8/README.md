Урок 8. Загрузка системы.

Вход без пароля в ОС, добавляем модуль в initd, переименовываем VG.


1. Попасть в систему без пароля несколькими способами
Способ 1.1. Способ работает с centos 7 и файловой системой mbr. Для centos 8 информации не нашел.
При выборе ядра загрузки нажать -e и ввести в конце строки начинающей с linux16:
init=/bin/sh
Нажать ctrl+x
Рутовая файловая система при это монтируется в режиме Read-Only. Чтобы примонтировать в режиме Read-Write:
mount -o remount,rw /
Способ 1.2.
В конце строки начинающейся с linux16 добавляем rd.break и нажимаем сtrl-x для загрузки в систему
Попадаем в emergency mode. Файловая система работает в режиме Read-Only, но мы не в ней. Выполняем слеующие действия чтобы получить пароль администратора:
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel
Способ 1.3
В строке начинающейся с linux16 заменяем ro на rw init=/sysroot/bin/sh и нажимаем сtrl-x для загрузки в систему


2. Установить систему с LVM, после чего переименовать VG
Первым делом посмотрим текущее состояние системы (нас интересует вторая строка с именем Volume Group):
vgs

VG #PV #LV #SN Attr   VSize   VFree
cs   1   2   0 wz--n- <29.00g    0

Приступим к переименованию:
vgrename cs otusroot

Далее правим /etc/fstab, /etc/default/grub, /boot/grub2/grub.cfg
Открываем все эти 3 файла по очереди в редакторе и меняем cs на otusroot
vim /etc/fstab
vim /etc/default/grub
vim /boot/grub2/grub.cfg
Пересоздаем initrd image, чтобы он знал новое название Volume Group:
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
Конфигурируем новый grub
grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
Перезагружаемся
reboot

3. Добавить модуль в initrd
В каталоге с скриптами модулей создаем папку с именем 01test:
mkdir /usr/lib/dracut/modules.d/01test
cd /usr/lib/dracut/modules.d/01test
В нее помещаем два скрипта:
vim module-setup.sh
------------
#!/bin/bash

check() {
    return 0
}

depends() {
    return 0
}

install() {
    inst_hook cleanup 00 "${moddir}/test.sh"
}
------------
vim test.sh
------------
#!/bin/bash

exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
cat <<'msgend'
Hello! You are in dracut module!
 ___________________
< I'm dracut module >
 -------------------
   \
    \
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/
msgend
sleep 10
echo " continuing...."
------------
Пересоздаем initrd image
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
Можно проверить/посмотреть какие модули загружены в образ:
lsinitrd -m /boot/initramfs-$(uname -r).img | grep test
Отредактируем grub.cfg убрав эти опции:rghb, quiet Для редактирования
vim /etc/default/grub
grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
reboot
В итоге при загрузке будет пауза на 10 секунд и пингвин в выводе терминала

