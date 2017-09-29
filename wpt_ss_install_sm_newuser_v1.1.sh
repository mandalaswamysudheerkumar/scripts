#!/bin/bash
#This Script Install webpagetest and showslow on same machine with port numbers
#Script prepared by Srikanth Thota
#version 1.1

### root or not ###
if [ `id -u` -ne 0 ]
then
echo "Run this script in root user only"
exit
fi
### root or not end ###

### Enter user Name ###
echo -n "Enter a newuser username: "
read newun
useradd -d /home/$newun -m $newun
passwd $newun


#### END ####


#### Enter ip address ####
echo -n "Enter your system ipaddress: "
read sys_ip
### Enter ip address end ###

############## Port number confirmation starting ##############
j=1

function calling {
echo "Please give the port numbers within the range  1024 and  65536: "
echo -n "Enter port number for webpagetest: "
read wpt_port
echo -n "Enter port number for showslow: "
read ss_port
}

function ports {
calling
while [ $j -gt 0 ]
do
#j=0

#port numbers are equal
if [ $wpt_port -eq $ss_port ]
then
echo "Both ports are same, you have to give different port numbers for webpagetest and showslow"
j=1
calling


#wpt port number not in range
elif [ "$wpt_port" -gt 1024 ] && [ "$wpt_port" -lt 65536 ] && [ "$ss_port" -gt 1024 ] && [ "$ss_port" -lt 65536 ]
then
echo "ports are in range"
j=0
else
echo "you entered wrong port range... again enter both ports"
j=1
calling
fi
done
}


ports

############## Port number confirmation ending ##############

#adding repository
sed -i '1i deb ftp://115.112.122.99:2333 ./' /etc/apt/sources.list
apt-get update

#installing apache, php and php modules
apt-get --allow-unauthenticated -y install unzip openssh-server apache2 php5 php5-json php5-gd php5-curl php5-apcu imagemagick ffmpeg libjpeg-progs exiftool php5-mysql php5-mcrypt libapache2-mod-php5 make

#apache configuration with webpagetest
cat <<EOF > /etc/apache2/sites-available/webpagetest.conf
Listen $wpt_port
<Directory "/var/www/webpagetest">
AllowOverride all
Order allow,deny
Allow from all
</Directory>
<VirtualHost *:$wpt_port>
DocumentRoot /var/www/webpagetest
</VirtualHost>
EOF

#apache configuration with showslow
cat <<EOF > /etc/apache2/sites-available/showslow.conf
Listen $ss_port
<VirtualHost *:$ss_port>
DocumentRoot /var/www/showslow
DirectoryIndex index.php
</VirtualHost>
EOF

####### Installing mysql for showslow ####
#installing mysql
export DEBIAN_FRONTEND=noninteractive
apt-get --allow-unauthenticated -y install mysql-server
update-rc.d mysql defaults
/etc/init.d/mysql start
####### Installation ends for mysql ####

######### Downloading packages ##########
#Downloading and extracting webpagetest
cd /tmp
wget  ftp://115.112.122.99:2333/webpagetest_2.13.zip
mkdir webpagetest
mv /tmp/webpagetest_2.13.zip /tmp/webpagetest
cd /tmp/webpagetest
unzip webpagetest_2.13.zip
mv /tmp/webpagetest/www /home/$newun/webpagetest
ln -s /home/$newun/webpagetest /var/www/

#Downloading, extracting and installing showslow
cd /tmp
#wget ftp://115.112.122.99:2333/showslow_1.2.2.tar.bz2
#wget http://www.showslow.org/downloads/showslow_1.2.1.tar.bz2
wget http://www.showslow.org/downloads/showslow_1.1.tar.bz2
tar -xjf /tmp/showslow_1.1.tar.bz2 -C /home/$newun
ln -s /home/$newun/showslow_1.1 /var/www/showslow

#create database and giving permissions
echo -n "Enter database name for showslow to create: "
read dbn
echo -n "Enter username for showslow db: "
read ssun
echo -n "Enter password for showslow user: "
read sspw
mysql -u root -e "create database $dbn;"
mysql -u root -e "grant usage on $dbn.* to $ssun@localhost identified by '$sspw';"
mysql -u root -e "grant all privileges on $dbn.* to $ssun@localhost;"

#configuring the showslow
cp /var/www/showslow/config.sample.php /var/www/showslow/config.php
sed -i '/\$db \= /c\$db = "'$dbn'";' /var/www/showslow/config.php
sed -i '/\$user \= /c\$user = "'$ssun'";' /var/www/showslow/config.php
sed -i '/\$pass \= /c\$pass = "'$sspw'";' /var/www/showslow/config.php

#making
cd /var/www/showslow
make

#keep .htacccess in showslow
cat <<EOF > /var/www/showslow/.htaccess
<IfModule mod_deflate.c>
# Insert filter
SetOutputFilter DEFLATE

# Netscape 4.x has some problems...
BrowserMatch ^Mozilla/4 gzip-only-text/html

# Netscape 4.06-4.08 have some more problems
BrowserMatch ^Mozilla/4\.0[678] no-gzip

# NOTE: Due to a bug in mod_setenvif up to Apache 2.0.48
# the above regex won't work. You can use the following
# workaround to get the desired effect:
BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html

# Don't compress images
SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png|ico)$ no-gzip
</IfModule> 

<IfModule mod_rewrite.c>
RewriteEngine on
RewriteRule ^(.*)\.(\d+)(_m_\d+)?\.([^\.]+)$    $1.$4    [L,QSA]
</IfModule> 

<IfModule mod_expires.c>
ExpiresActive On
ExpiresByType image/png "access plus 1 year"
ExpiresByType image/gif "access plus 1 year"
ExpiresByType image/jpeg "access plus 1 year"
ExpiresByType image/vnd.microsoft.icon "access plus 1 year"
ExpiresByType text/css "access plus 1 year"
ExpiresByType application/x-javascript "access plus 1 year"
ExpiresByType application/javascript "access plus 1 year"
ExpiresByType text/javascript "access plus 1 year"
</IfModule>
EOF

######### Downloading packages end ##########

###### enabling modules for apache and php #####
a2enmod expires
a2enmod headers
a2enmod rewrite
a2enmod deflate

cp /etc/php5/conf.d/mcrypt.ini /etc/php5/mods-available/
php5enmod mcrypt
/etc/init.d/apache2 restart
###### enabling modules for apache and php ends #####

### change php settings and configuration files ###
sed -i '/upload_max_filesize/c\upload_max_filesize \= \20M' /etc/php5/apache2/php.ini
sed -i '/post_max_size/c\post_max_size \= \20M' /etc/php5/apache2/php.ini

#change ownership of webpagetest
#chown -R www-data "/var/www/webpagetest"

#configuration in settings.ini
cp /var/www/webpagetest/settings/settings.ini.sample /var/www/webpagetest/settings/settings.ini
sed -i '/publishTo=www.webpagetest.org/c\;publishTo=www.webpagetest.org' /var/www/webpagetest/settings/settings.ini

echo " " >> /var/www/webpagetest/settings/settings.ini
echo "showslow=http://$sys_ip:$ss_port/" >> /var/www/webpagetest/settings/settings.ini
echo "beaconRate=100" >> /var/www/webpagetest/settings/settings.ini

chown -R $newun:$newun /home/$newun/webpagetest
chown -R $newun:$newun /home/$newun/showslow_1.1
chmod -R 777 /var/www/webpagetest/results/
chmod -R 777 /var/www/webpagetest/work/
chmod -R 777 /var/www/webpagetest/tmp/
chmod -R 777 /var/www/webpagetest/logs/

#asking webpagetest url for showslow
sed -i '/\$webPageTestBase \= /c\$webPageTestBase = "'http://$sys_ip:$wpt_port/'";' /var/www/showslow/global.php
### change php settings and configuration files end ###

### Apache restarting ###
a2ensite webpagetest
a2ensite showslow
service apache2 restart
### Apache restarting end ###
