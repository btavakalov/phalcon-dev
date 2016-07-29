#!/usr/bin/env bash
git pull --all

echo '******************************************************************************'
#export IP=10.10.02.1
export HOST_IP=$(ifconfig `netstat -nr | awk '{ if ($1 ~/default/) { print $6; exit } }'` | grep "inet " | awk '{ print $2 }')
export GIT_BRANCH=`git rev-parse --abbrev-ref HEAD`

export APP_IMAGE="phalcon-sandbox"
export APP_CONTAINER="phalcon-sandbox"

export NGINX_IMAGE="phalcon-sandbox-nginx"
export NGINX_CONTAINER="phalcon-sandbox-nginx"

export PHP_IMAGE="phalcon-sandbox-php"
export PHP_CONTAINER="phalcon-sandbox-php"

export POSTGRES_IMAGE="ironlion/postgres"
export POSTGRES_CONTAINER="phalcon-sandbox-postgres"

echo 'Setup vars'
echo "GIT_BRANCH = $GIT_BRANCH"
echo "HOST_IP = $HOST_IP"

echo "APP_IMAGE = $APP_IMAGE"
echo "APP_CONTAINER = $APP_CONTAINER"

echo "NGINX_IMAGE = $NGINX_IMAGE"
echo "NGINX_CONTAINER = $NGINX_CONTAINER"

echo "PHP_IMAGE = $PHP_IMAGE"
echo "PHP_CONTAINER = $PHP_CONTAINER"

echo '******************************************************************************'
echo "* Build '$APP_IMAGE' image"
echo '******************************************************************************'
docker build -t $APP_IMAGE .

echo '******************************************************************************'
echo "* Build '$NGINX_IMAGE' image"
echo '******************************************************************************'
docker build -t $NGINX_IMAGE services/nginx

echo '******************************************************************************'
echo "* Build '$PHP_IMAGE' image"
echo '******************************************************************************'
docker build -t $PHP_IMAGE services/php

echo '******************************************************************************'
echo "* Stop & rm '$APP_CONTAINER' container"
echo '******************************************************************************'
docker stop $APP_CONTAINER
docker rm $APP_CONTAINER

echo '******************************************************************************'
echo "* Stop & rm '$NGINX_CONTAINER' container"
echo '******************************************************************************'
docker stop $NGINX_CONTAINER
docker rm $NGINX_CONTAINER

echo '******************************************************************************'
echo "* Stop & rm '$POSTGRES_CONTAINER' container"
echo '******************************************************************************'
docker stop $POSTGRES_CONTAINER
docker rm $POSTGRES_CONTAINER

echo '******************************************************************************'
echo "* Stop & rm '$PHP_CONTAINER' container"
echo '******************************************************************************'
docker stop $PHP_CONTAINER
docker rm $PHP_CONTAINER

echo '******************************************************************************'
echo "* Run '$APP_CONTAINER' container"
echo '******************************************************************************'
docker run \
        --name $APP_CONTAINER \
        --volume $(pwd)/app:/app \
        $APP_IMAGE \
        true

echo '******************************************************************************'
echo "* Run postgres container"
echo '******************************************************************************'
docker run -d \
        --name $POSTGRES_CONTAINER \
        --env POSTGRES_PASSWORD=123 \
        --env PGDATA=/storage/db \
        --volumes-from $APP_CONTAINER \
        $POSTGRES_IMAGE

sleep 10

echo '******************************************************************************'
echo "* Run '$PHP_CONTAINER' container"
echo '******************************************************************************'
docker run -d \
        --name $PHP_CONTAINER \
        --env XDEBUG_CONFIG="remote_host=$HOST_IP" \
        --volumes-from $APP_CONTAINER \
        --link $POSTGRES_CONTAINER:postgres \
        $PHP_IMAGE

echo '******************************************************************************'
echo "* Run '$NGINX_CONTAINER' container"
echo '******************************************************************************'
docker run -d \
        --name $NGINX_CONTAINER \
        --volumes-from $APP_CONTAINER \
        --link $PHP_CONTAINER:php-fpm \
        -p 80:80 \
        $NGINX_IMAGE

echo '******************************************************************************'
echo "PHP Container log "
echo '******************************************************************************'
docker logs -f $PHP_CONTAINER

#docker exec -it $NGINX_CONTAINER bash
#docker exec -it $PHP_CONTAINER bash
