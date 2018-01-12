#Hitcon 2017 web ssrfme
#
#mysql root密码 : Pr0ph3t
#其余环境与题目大致无异
#如要修改root与题目用户密码请用 [docker exec -it '你的应用名称' /bin/bash] 进入容器修改
#usage : 
#    进入Dockerfile目录
#    [docker build -t '自定义镜像名字' . ] //最后的.别少了
#    [docker run -id --name '你的应用名称' -p 外部端口:80 -m '内存限制 如1g、500m' '你的自定义镜像名称' /run.sh]

#整合 apache php7
FROM pr0ph3t/lap7
MAINTAINER Pr0ph3t <1415314884@qq.com>

#Install crontab and perl with LWP
RUN apt-get update -y && apt-get install cron -y && apt-get install perl -y && apt-get install libwww-perl -y && apt-get install curl -y

#Init crontab , 每天凌晨4点清空sandbox文件夹
RUN echo '0 4 * * * root rm -rf /var/www/html/sandbox/*' >> /etc/crontab

#Init challenge
ADD index.php /var/www/html/
ADD readflag /readflag
RUN rm -rf /var/www/html/index.html
RUN mkdir /var/www/html/sandbox
RUN chown www-data /var/www/html/sandbox
RUN chmod -R 775 /var/www/html/sandbox
RUN useradd -m -s /sbin/nologin orange
RUN echo 'hitcon{Perl_<3_y0u}' > /flag

#Configure the apache2.config
RUN sed 's/Indexes //' /etc/apache2/apache2.conf > /etc/apache2/apache2.conf.new
RUN mv /etc/apache2/apache2.conf.new /etc/apache2/apache2.conf
RUN echo -e '<Directory "/var/www/html/sandbox">\n\tphp_flag engine off\n</Directory>' >> /etc/apache2/site-enabled/000-default.conf

#Create run.sh
ADD run.sh /
RUN chmod +x /run.sh


#Expose http service
EXPOSE 80
CMD ["bash -x /run.sh"]