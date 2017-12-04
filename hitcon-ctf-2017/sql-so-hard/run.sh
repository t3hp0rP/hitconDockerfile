#!/bin/sh
service cron start

service mysql start

service postgresql start

#Init postgresql
su postgres -c 'psql -c \\i /root/psqlInit.sql'

#Init mysql
mysql -uroot -pPr0ph3t < /root/mysqlInit.sql

#clean sql file
if [ ! -f \'/root/mysqlInit.sql\' ]; then
	rm -rf /root/mysqlInit.sql
fi
if [ ! -f \'/root/psqlInit.sql\' ]; then
	rm -rf /root/psqlInit.sql
fi

su ctf
cd ~
source .bashrc
cd ~/app
nvm use 4.6.0
nohup node app.js &

/bin/bash