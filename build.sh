#!/bin/sh
docker build \
    --build-arg=["BASEREPO=$BASEREPO","EPELREPO=$EPELREPO"] \
    -t vertigo/lets-nginx .
