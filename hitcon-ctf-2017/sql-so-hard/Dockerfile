#Hitcon 2017 web sql_so_hard
#
#mysql root密码 : Pr0ph3t
#postgresql postgresql密码 : Pr0ph3t
#其余环境与题目无异
#如要修改root与题目用户密码请用 [docker exec -it '你的应用名称' /bin/bash] 进入容器修改
#usage : 
#    进入Dockerfile目录
#    [docker build -t '自定义镜像名字' . ] //最后的.别少了
#    [docker run -itd --name '你的应用名称' -p 外部端口:80 -m '内存限制 如1g、500m' '你的自定义镜像名称' /run.sh]

FROM pr0ph3t/mysql

#replace sh with bash
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

#Install nc && postgresql && cron
RUN apt-get update && apt-get install -y netcat postgresql cron curl

#Init cron , 每60s清除hall of shame
RUN echo "0 */1 * * * root mysql -u ban -pban -e 'truncate table bandb.blacklists'" >> /etc/crontab

#Create user to run server
RUN useradd -m -s /bin/bash ctf
ADD install.sh /home/ctf/
RUN chmod +x /home/ctf/install.sh
ENV NVM_DIR /home/ctf/.nvm
ENV NODE_VERSION 4.6.0

#Copy init file
ADD app.js /home/ctf/
ADD mysqlInit.sql /home/ctf/
ADD psqlInit.sql /home/ctf/
ADD run.sh /
RUN chmod +x /run.sh

RUN echo "echo 'hitcon{if_you_dont_know_why_plz_check_mysql_max_allowed_packet}'" > /readflag
RUN chmod +x /readflag

#Expose
EXPOSE 31337
CMD ["bash -x /run.sh"]