#!/bin/sh
docker stop lets-nginx
docker rm lets-nginx
docker run --detach \
    --name lets-nginx \
    --link web-backend:backend \
    --env EMAIL=andre@vertigo.com.br \
    --env DOMAIN=vertigo.noip.me \
    --env UPSTREAM=backend:80 \
    --publish 80:80 \
    --publish 443:443 \
    --volume letsencrypt:/etc/letsencrypt \
    --volume letsencrypt-backups:/var/lib/letsencrypt \
    --volume dhparam-cache:/cache \
    vertigo/lets-nginx
