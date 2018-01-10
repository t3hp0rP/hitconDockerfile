#!/bin/sh
service cron start

service mysql start

service postgresql start

#Init postgresql
su postgres -c 'psql -f /home/ctf/psqlInit.sql'

#Init mysql
mysql -uroot -pPr0ph3t < /home/ctf/mysqlInit.sql

#clean sql file
if [ ! -f \'/home/ctf/mysqlInit.sql\' ]; then
	rm -rf /home/ctf/mysqlInit.sql
fi
if [ ! -f \'/home/ctf/psqlInit.sql\' ]; then
	rm -rf /home/ctf/psqlInit.sql
fi

nohup su ctf <<EOF

cd /home/ctf/
/home/ctf/install.sh
source /home/ctf/.nvm/nvm.sh
nvm install $NODE_VERSION
nvm use $NODE_VERSION
npm install express-generator -g
express app

#Init app env
cd /home/ctf/app/
npm install express
npm install pg@7.0.2
npm install mysql
npm install qs
mv /home/ctf/app.js /home/ctf/app/

node app.js
EOF &