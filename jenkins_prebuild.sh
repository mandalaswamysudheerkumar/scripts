#!/bin/bash

db_host="localhost"
db_name_HolaEnterprises="holadev_new"
db_user="root"
db_pass="gwf"
dr_backup="/usr/local/tomcat/webapps"
backup_loc="/backup/deployment"
dat=`date +%Y_%m_%d_%H_%M_%S`

mkdir -p $backup_loc/$dat

/etc/init.d/tomcat stop
killall -9 java

#Taking mysql Dump

mysqldump -h "$db_host" -u "$db_user" -p"$db_pass" "$db_name_HolaEnterprises" > "$backup_loc/$dat/$db_name_HolaEnterprises.sql"

#Taking webapps backup 

cp -rf "$dr_backup/HolaEnterprise" "$backup_loc/$dat/"
cp -rf "$dr_backup/HolaEnterprise.war" "$backup_loc/$dat/"

tar -cjf $backup_loc/$dat.tar.bz2 $backup_loc/$dat
rm -rf $dr_backup/HolaEnterprise.war
rm -rf $dr_backup/HolaEnterprise
rm -rf $backup_loc/$dat

find $backup_loc -mtime +5 -exec rm -rvf {} \;

