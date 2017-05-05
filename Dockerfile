FROM phusion/baseimage
MAINTAINER Abdi Darmawan <abdid46@gmail.com>

# ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# change resolv.conf
#RUN echo 'nameserver 8.8.8.8' > /etc/resolv.conf

# setup
ENV HOME /root
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

CMD ["/sbin/my_init"]

# Set the timezone Asia/Jakarta
RUN echo "Asia/Jakarta" > /etc/timezone && rm /etc/localtime && dpkg-reconfigure -f noninteractive tzdata


# nginx-php installation
RUN DEBIAN_FRONTEND="noninteractive" apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y upgrade
RUN DEBIAN_FRONTEND="noninteractive" apt-get update --fix-missing
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install php7.0
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install php7.0-fpm php7.0-common php7.0-cli php7.0-mysqlnd php7.0-mcrypt php7.0-curl php7.0-pspell php7.0-intl php7.0-bcmath php7.0-mbstring php7.0-soap php7.0-xml php7.0-zip php7.0-json php7.0-imap php-xdebug php-redis

# install nginx (full)
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y nginx-full

# install latest version of nodejs
#RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y nodejs
#RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y npm
#RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y git

# install php composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# add build script (also set timezone to Asia/Jakarta)
RUN mkdir -p /root/setup
ADD build/setup.sh /root/setup/setup.sh
RUN chmod +x /root/setup/setup.sh
RUN (cd /root/setup/; /root/setup/setup.sh)

# copy costume php.ini (session redis etc)
ADD build/php.ini /etc/php/7.0/fpm/php.ini

# copy config tweak sysctl
ADD build/sysctl.conf /etc/sysctl.conf

# copy files from repo nginx vhost
ADD build/nginx.conf /etc/nginx/nginx.conf
ADD build/vhost.conf /etc/nginx/sites-available/default
ADD build/.bashrc /root/.bashrc

# disable services start
RUN update-rc.d -f apache2 remove
RUN update-rc.d -f nginx remove
RUN update-rc.d -f php7.0-fpm remove

# add startup scripts for nginx
ADD build/nginx.sh /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run

# add startup scripts for php7.0-fpm
ADD build/phpfpm.sh /etc/service/phpfpm/run
RUN chmod +x /etc/service/phpfpm/run

# set WWW public folder
RUN mkdir -p /var/www/public



### add code to docker ###
ADD code-app/* /var/www/public/


# set owner and permission folder #
RUN chown -R www-data:www-data /var/www
RUN chmod 755 /var/www

# set terminal environment
ENV TERM=xterm

# port and settings
EXPOSE 80 9000

# cleanup apt and lists
RUN apt-get clean
RUN apt-get autoclean
