#!/bin/bash

# Определяем публичный IP-адрес и настраиваем его в конфиге
public_ip=$(wget -qO- https://ipecho.net/plain)

# Обновляем пакеты и устанавливаем Apache, MySQL, PHP и необходимые зависимости
sudo apt update
sudo apt-get install apache2 mysql-client mysql-server php libapache2-mod-php -y
sudo apt-get install graphviz aspell ghostscript php-pspell php-curl php-gd php-intl php-mysql php-xml php-xmlrpc php-ldap php-zip php-soap php-mbstring git -y
sudo a2enmod rewrite

# Перезапускаем Apache
sudo service apache2 restart

# Меняем max_input_vars на 6000
sudo sed -i 's/;max_input_vars = 1000/max_input_vars = 6000/' /etc/php/8.3/apache2/php.ini
sudo sed -i 's/;max_input_vars = 1000/max_input_vars = 6000/' /etc/php/8.3/cli/php.ini

# Клонируем Moodle из официального репозитория
cd /opt
sudo git clone -b MOODLE_405_STABLE git://git.moodle.org/moodle.git  

# Копируем файлы Moodle в директорию Apache
sudo cp -R /opt/moodle /var/www/html/

# Создаем директорию moodledata и задаем права доступа
sudo mkdir /var/www/moodledata
sudo chown -R www-data:www-data /var/www/moodledata
sudo chmod -R 770 /var/www/moodledata

# Устанавливаем правильные права для директории Moodle
sudo chown -R www-data:www-data /var/www/html/moodle
sudo chmod -R 755 /var/www/html/moodle

# Настройка базы данных MySQL для Moodle
sudo mysql -u root << EOF
CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'moodledude'@'localhost' IDENTIFIED BY 'passwordformoodledude';
GRANT ALL PRIVILEGES ON moodle.* TO 'moodledude'@'localhost';
FLUSH PRIVILEGES;
EOF

# Настройка Apache для Moodle
# Путь к файлу конфигурации
conf_file="/etc/apache2/sites-available/moodle.conf"

# Используем echo для создания файла moodle.conf
sudo echo "<VirtualHost *:80>
    ServerAdmin admin@$public_ip
    DocumentRoot /var/www/html/moodle
    ServerName $public_ip
    ServerAlias www.$public_ip

    <Directory /var/www/html/moodle>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/moodle_error.log
    CustomLog \${APACHE_LOG_DIR}/moodle_access.log combined
</VirtualHost>" | sudo tee $conf_file
sudo service apache2 restart

# Используем echo для создания файла config.php
:'moodle_config="/var/www/html/moodle/config.php"

sudo echo "<?php  // Moodle configuration file

unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'mysqli';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'localhost';
$CFG->dbname    = 'moodle';
$CFG->dbuser    = 'moodledude';
$CFG->dbpass    = 'passwordformoodledude';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbport' => '',
  'dbsocket' => '',
  'dbcollation' => 'utf8mb4_unicode_ci',
);

$CFG->wwwroot   = 'http://$public_ip/moodle';
$CFG->dataroot  = '/var/www/moodledata';
$CFG->admin     = 'admin';

$CFG->directorypermissions = 0777;

require_once(__DIR__ . '/lib/setup.php');

// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!" | sudo tee $moodle_config 


# Копируем файл конфигурации и настраиваем его
#sudo cp /var/www/html/moodle/config-dist.php /var/www/html/moodle/config.php
#cd /var/www/html/moodle

# Вносим изменения в конфигурацию Moodle
#sudo sed -i "s/'pgsql'/'mysqli'/1" config.php
#sudo sed -i "s/'username'/'moodledude'/1" config.php
#sudo sed -i "s/'password'/'passwordformoodledude'/1" config.php
#sudo sed -i "s#'localhost'#$public_ip#1" config.php


#sudo sed -i "136 s#'http://example.com/moodle'#'http://$public_ip/moodle'#1" config.php
#sudo sed -i "s#'home/example'#'/var'#1" config.php

# Перезапускаем Apache для применения всех изменений
sudo service apache2 restart

# Сообщение о завершении
# echo "Установка Moodle завершена. Откройте браузер и перейдите по адресу: http://$public_ip/moodle"
