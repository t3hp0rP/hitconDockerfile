#Hitcon 2017 web baby^h-master-php-2017
#
#read_secret输出OrangeOrangeOrange
#MaxConnectionsPerChild为100
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
RUN apt-get update -y && apt-get install cron -y

#Init crontab , 每天凌晨4点清空data文件夹
RUN echo '0 4 * * * root rm -rf /var/www/data/*' >> /etc/crontab

#Init challenge
ADD index.php /var/www/html/
ADD readflag /read_flag
ADD read_secret /read_secret
ADD avatar-1.gif /var/www/html/avatar.gif
RUN chmod u+s /read_flag
RUN rm -rf /var/www/html/index.html
RUN mkdir /var/www/data
RUN chown www-data /var/www/data
RUN chmod -R 775 /var/www/data
RUN echo 'hitcon{Th3 d4rk fl4m3 PHP Mast3r}' > /flag
RUN chmod 700 /flag

#Configure the apache2
RUN sed 's/Indexes //' /etc/apache2/apache2.conf > /etc/apache2/apache2.conf.new
RUN sed 's/MaxConnectionsPerChild   0/MaxConnectionsPerChild   100/' /etc/apache2/mods-available/mpm_prefork.conf > /etc/apache2/mods-available/mpm_prefork.conf.new
RUN mv /etc/apache2/apache2.conf.new /etc/apache2/apache2.conf
RUN mv /etc/apache2/mods-available/mpm_prefork.conf.new /etc/apache2/mods-available/mpm_prefork.conf
RUN echo '<Directory "/var/www/data">\n\tphp_flag engine off\n</Directory>' >> /etc/apache2/sites-enabled/000-default.conf

#Create run.sh
ADD run.sh /
RUN chmod +x /run.sh


#Expose http service
EXPOSE 80
CMD ["bash -x /run.sh"]