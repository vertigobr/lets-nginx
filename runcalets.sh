#!/bin/sh
docker stop lets-nginx
docker rm lets-nginx
SSLCLIENTCA=`cat /tmp/ca.pem`
echo "SSLCLIENTCA:"
echo "$SSLCLIENTCA"
docker run --detach \
    --name lets-nginx \
    --link web-backend:backend \
    --env EMAIL=andre@vertigo.com.br \
    --env DOMAIN=vertigo.webhop.me \
    --env UPSTREAM=backend:80 \
    --env "SSLCLIENTCA=$SSLCLIENTCA" \
    --publish 80:80 \
    --publish 443:443 \
    --volume letsencrypt:/etc/letsencrypt \
    --volume letsencrypt-backups:/var/lib/letsencrypt \
    --volume dhparam-cache:/cache \
    vertigo/lets-nginx
