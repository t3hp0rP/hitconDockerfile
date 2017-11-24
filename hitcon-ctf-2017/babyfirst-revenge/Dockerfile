#Hitcon 2017 web babyfirst_revenge
#
#mysql root密码 : Pr0ph3t
#其余环境与题目无异
#usage : 
#    进入Dockerfile目录
#    docker build -t '自定义镜像名字' .  //最后的.别少了
#    docker run -id --name '你的应用名称' -p 外部端口:80 -m '内存限制 如1g、500m' '你的自定义镜像名称' /run.sh

#整合lamp
FROM pr0ph3t/lamp
MAINTAINER Pr0ph3t <1415314884@qq.com>

#Install crontab

RUN apt-get update -y && apt-get install cron -y

#Init crontab

RUN echo '0 4 * * * root rm -rf /var/www/sandbox/*' >> /etc/crontab

#Init challenge

ADD index.php /var/www/html/
ADD init.sql /var/www/
RUN rm -rf /var/www/html/index.html
RUN mkdir /var/www/sandbox
RUN chown www-data /var/www/sandbox
RUN chmod -R 775 /var/www/sandbox
RUN useradd -m -s /sbin/nologin fl4444g
RUN echo 'Flag is in the MySQL database\nfl4444g / SugZXUtgeJ52_Bvr' > /home/fl4444g/README.txt

#Create run.sh
ADD run.sh /
RUN chmod +x /run.sh


#Expose http service
EXPOSE 80
CMD ["bash -x /run.sh"]