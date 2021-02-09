#!/bin/bash

# Развернуть новый сайт
#
# 

if [ "$1" == "" ]; then
    echo Укажите название сайта. Например, x.ru
    exit 1
fi

echo 127.0.0.1 $1 > /etc/hosts

mkdir -p $1/htdocs/cgi-bin
mkdir -p $1/logs

echo << END > $1/htdocs/.htaccess
AddHandler cgi-script .cgi .pl
RewriteEngine on
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^ /cgi-bin/handler.pl [L]
END
