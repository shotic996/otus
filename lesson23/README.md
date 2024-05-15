# Задание 22. Пользователь и группы. Авторизация и аутентификация PAM.

## Задание

Запретить всем пользователям, кроме группы admin, логин в выходные (суббота и воскресенье), без учета праздников

## Скрипт
-----------------------
#!/bin/bash
#Первое условие: если день недели суббота или воскресенье
if [ $(date +%a) = "Sat" ] || [ $(date +%a) = "Sun" ]; then
 #Второе условие: входит ли пользователь в группу admin
 if getent group admin | grep -qw "$PAM_USER"; then
        #Если пользователь входит в группу admin, то он может подключиться
        exit 0
      else
        #Иначе ошибка (не сможет подключиться)
        exit 1
    fi
  #Если день не выходной, то подключиться может любой пользователь
  else
    exit 0
fi
----------------------------

## Инструкция


1. Подключаемся к нашей созданной ВМ: vagrant ssh
2. Переходим в root-пользователя: sudo -i
3. Создаём пользователя otusadm и otus: useradd otusadm && useradd otus
4. Создаём пользователям пароли: echo "Otus2022!" | passwd --stdin otusadm && echo "Otus2022!" | passwd --stdin otus
5. Создаём группу admin: groupadd -f admin
6. Добавляем пользователей vagrant,root и otusadm в группу admin:
usermod otusadm -a -G admin && usermod root -a -G admin && usermod vagrant -a -G admin

Проверяем подключение по ssh. Должны подключаться оба пользователя (otus, otusadm).

7. Создаем скрипт, который приведен выше по пути:
vim /usr/local/bin/login.sh

8. Добавим права chmod +x /usr/local/bin/login.sh
9. Корректируем PAM файл и в отличии от методички добавляем однту строку в конец файла.

```
# /etc/pam.d/sshd
# ...
auth required pam_exec.so /usr/local/bin/login.sh
```

Перезапускаем сервис
systemctl restart sshd

Отключаемся от ВМ и повторно пробуем подключиться пользователями otus и otusadm.


Пользователь otusadm заходит без проблем, под пользователем otus зайти не можем.
