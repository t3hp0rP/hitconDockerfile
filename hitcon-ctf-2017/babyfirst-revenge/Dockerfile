#Hitcon 2017 web babyfirst_revenge
#
#mysql root密码 : Pr0ph3t
#其余环境与题目无异
FROM pr0ph3t/hitcon2017_babyfirst_revenge
MAINTAINER Pr0ph3t "1415314884@qq.com"

# create run.sh
RUN touch /run.sh \
	&& echo '#!/bin/sh' >> /run.sh \
	&& echo '' >> run.sh \
	&& echo 'service apache2 start' >> run.sh \
	&& echo '' >> run.sh \
	&& echo 'service mysql start' >> run.sh \
	&& chmod +x /run.sh

#start http && mysql
CMD ["/run.sh"]