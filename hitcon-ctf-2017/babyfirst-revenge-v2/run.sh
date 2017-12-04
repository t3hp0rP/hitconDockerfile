#!/bin/sh
service cron start

service apache2 start

service mysql start

mysql -uroot -pPr0ph3t < /var/www/init.sql

if [ ! -f \'/var/www/init.sql\' ]; then
	rm -rf /var/www/init.sql
fi

/bin/bash