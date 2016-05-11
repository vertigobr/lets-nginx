#!/bin/sh
#
# sample backend service
# port binding in unnecessary, just use it for troubleshooting and remove it later
#
docker run --name web-backend -d \
  -p 8000:80 \
  nginx
