#!/bin/sh
docker stop lets-nginx
docker rm lets-nginx
docker run --detach \
    --name lets-nginx \
    --link web-backend:backend \
    --env EMAIL=me@email.com \
    --env DOMAIN=vertigo.noip.me \
    --env UPSTREAM=backend:80 \
    --env STAGING=1 \
    --publish 80:80 \
    --publish 443:443 \
    --volume letsencrypt:/etc/letsencrypt \
    --volume letsencrypt-backups:/var/lib/letsencrypt \
    --volume dhparam-cache:/cache \
    vertigo/lets-nginx
