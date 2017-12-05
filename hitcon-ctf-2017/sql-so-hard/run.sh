#!/bin/sh
service cron start

service mysql start

service postgresql start

#Init postgresql
su postgres -c 'psql -c \\i /home/ctf/psqlInit.sql'

#Init mysql
mysql -uroot -pPr0ph3t < /home/ctf/mysqlInit.sql

#clean sql file
if [ ! -f \'/home/ctf/mysqlInit.sql\' ]; then
	rm -rf /home/ctf/mysqlInit.sql
fi
if [ ! -f \'/home/ctf/psqlInit.sql\' ]; then
	rm -rf /home/ctf/psqlInit.sql
fi

# bash -i -c 'nvm use 4.6.0'
cd /home/ctf/
/home/ctf/install.sh
nvm install $NODE_VERSION
nvm use $NODE_VERSION
npm install express-generator -g
express app

#Init app env
cd /home/ctf/app/
bash -i -c 'npm install express'
bash -i -c 'npm install pg@7.0.2'
bash -i -c 'npm install mysql'
bash -i -c 'npm install qs'
mv /home/ctf/app.js /home/ctf/app/
touch /home/ctf/app/nohup.out
chown ctf /home/ctf/app/nohup.out
chmod 755 /home/ctf/app/nohup.out

nohup bash -i -c 'node app.js' &

/bin/bash