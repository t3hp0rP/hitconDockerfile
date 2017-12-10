#!/bin/sh
service cron start

service mysql start

service postgresql start

#Init postgresql
su postgres -c 'psql -f /home/ctf/psqlInit.sql'

#Init mysql
mysql -uroot -pPr0ph3t < /home/ctf/mysqlInit.sql

#clean sql file
# if [ ! -f \'/home/ctf/mysqlInit.sql\' ]; then
# 	rm -rf /home/ctf/mysqlInit.sql
# fi
# if [ ! -f \'/home/ctf/psqlInit.sql\' ]; then
# 	rm -rf /home/ctf/psqlInit.sql
# fi

su ctf <<EOF

cd /home/ctf/
/home/ctf/install.sh
bash -i -c 'nvm install $NODE_VERSION'
bash -i -c 'nvm use $NODE_VERSION'
bash -i -c 'npm install express-generator -g'
bash -i -c 'express app'

#Init app env
cd /home/ctf/app/
bash -i -c 'npm install express'
bash -i -c 'npm install pg@7.0.2'
bash -i -c 'npm install mysql'
bash -i -c 'npm install qs'
mv /home/ctf/app.js /home/ctf/app/

nohup bash -i -c 'node app.js' &

EOF
/bin/bash