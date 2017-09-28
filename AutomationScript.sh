#!/bin/sh
git remote update origin

ORIGIN=$(git rev-parse remotes/origin/stg-master)
STAGING=$(git rev-parse remotes/staging/master)

if [ $ORIGIN = $STAGING ]; then
    echo "Up-to-date"
else
    git fetch origin stg-master
    git push staging origin/stg-master:master
    rsync -avzh zaidm@192.168.8.62:/var/www/html/magento2-develop/pub/media/  /home/testcloud/html/Pub/media
    rsync -avzh /home/testcloud/html/Pub/media/ zaidm@192.168.8.62:~/ZaidM/media
fi
