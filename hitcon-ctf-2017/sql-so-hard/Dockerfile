#Hitcon 2017 web sql_so_hard
#
#mysql root密码 : Pr0ph3t
#postgresql postgresql密码 : Pr0ph3t
#其余环境与题目无异
#如要修改root与题目用户密码请用 [docker exec -it '你的应用名称' /bin/bash] 进入容器修改
#usage : 
#    进入Dockerfile目录
#    [docker build -t '自定义镜像名字' . ] //最后的.别少了
#    [docker run -id --name '你的应用名称' -p 外部端口:80 -m '内存限制 如1g、500m' '你的自定义镜像名称' /run.sh]

FROM pr0ph3t/nodejsmysql

#Install nc && postgresql && cron
RUN apt-get update && apt-get install -y netcat postgresql cron curl

#Init cron , 每60s清除hall of shame
RUN echo "0 */1 * * * root mysql -u userdb -puserdb -e \'truncate table blacklists\'" >> /etc/crontab

#Create user to run server
RUN useradd -m -s /bin/bash ctf
ADD install.sh /home/ctf/
RUN chmod +x /home/ctf/install.sh
RUN su ctf -c 'bash /home/ctf/install.sh'
ENV NVM_DIR /home/ctf/.nvm
RUN [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
RUN nvm install 4.6.0
RUN nvm use 4.6.0
WORKDIR /home/ctf/
RUN npm install express-generator -g
RUN express app

#Copy init file
ADD app.js /home/ctf/app/
ADD mysqlInit.sql /home/ctf/
ADD psqlInit.sql /home/ctf/
ADD run.sh /
RUN chmod +x /run.sh


RUN touch /home/ctf/app/nohup.out
RUN chown ctf /home/ctf/app/nohup.out
RUN chmod 755 /home/ctf/app/nohup.out
RUN echo "echo \'hitcon{if_you_dont_know_why_plz_check_mysql_max_allowed_packet}\'" > /readflag

#Init app env
WORKDIR /home/ctf/app/
RUN npm install express
RUN npm install pg@7.0.2
RUN npm install mysql
RUN npm install qs

#Expose
EXPOSE 31337
CMD ["bash -x /run.sh"]