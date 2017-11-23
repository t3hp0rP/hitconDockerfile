#Hitcon 2017 web babyfirst_revenge
#
#mysql root密码 : Pr0ph3t
#其余环境与题目无异

#冗余？
# FROM pr0ph3t/hitcon2017_babyfirst_revenge
# MAINTAINER Pr0ph3t "1415314884@qq.com"

# # create run.sh
# RUN touch /run.sh \
# 	&& echo '#!/bin/sh' >> /run.sh \
# 	&& echo '' >> run.sh \
# 	&& echo 'service apache2 start' >> run.sh \
# 	&& echo '' >> run.sh \
# 	&& echo 'service mysql start' >> run.sh \
# 	&& chmod +x /run.sh

# #start http && mysql
# CMD ["/run.sh"]


#整合lamp
FROM pr0ph3t/lamp
MAINTAINER Pr0ph3t <1415314884@qq.com>

#Install crontab

RUN apt-get update -y && apt-get install crontab -y

#Init crontab

RUN echo '0 4 * * * root rm -rf /var/www/sandbox/*' >> /etc/crontab

#Init challenge

ADD index.php /var/www/html/
ADD init.sql /var/www/html/
RUN rm -rf /var/www/html/index.html
RUN mkdir /var/www/sandbox
RUN chown www-data /var/www/sandbox
RUN chmod -R 775 /var/www/sandbox
RUN useradd -m -s /sbin/nologin fl4444g
RUN echo -e 'Flag is in the MySQL database\nfl4444g / SugZXUtgeJ52_Bvr' > /home/fl4444g/README.txt

RUN service mysql start
RUN mysql -uroot -pPr0ph3t < /var/www/html/init.sql
RUN rm -rf /var/www/html/init.sql

#Create run.sh
RUN touch /run.sh \
	&& echo '#!/bin/sh' >> /run.sh \
	&& echo '' >> run.sh \
	&& echo 'service apache2 start' >> run.sh \
	&& echo '' >> run.sh \
	&& echo 'service mysql start' >> run.sh \
	&& chmod +x /run.sh

#Expose http service
EXPOSE 80
CMD ['/run.sh']