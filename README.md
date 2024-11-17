# Avroid_test  

## Описание  
Данная утилита устанавливает Debian, используя debootstrap, в заданную директорию с указанного зеркала.  

## Сборка  
В корневой директории выполнить:  
```
dpkg-buildpackage -uc -us
```

## Запуск  
```
sudo avroid_test.sh <install_path> <mirror>
```
install_path -- директория, в которую будет выполнена установка.  
mirror -- зеркало, с которого будет выполняться загрузка.  
Если данный аргумент не задан, будет использоваться http://ftp.ru.debian.org/debian/
