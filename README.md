# Let's Nginx

[![Build Status](http://drone.vertigo.com.br/api/badges/vertigobr/lets-nginx/status.svg)](http://drone.vertigo.com.br/vertigobr/lets-nginx)
[![](https://badge.imagelayers.io/vertigo/lets-nginx:latest.svg)](https://imagelayers.io/?images=vertigo/lets-nginx:latest 'Get your own badge on imagelayers.io')

*[dockerhub build](https://hub.docker.com/r/vertigo/lets-nginx/)*

CentOS-based nginx with automated SSL certificate (letsencrypt).

Based on [smashwilson/lets-nginx](https://github.com/smashwilson/lets-nginx). You can read the [original README](README.original.md) as well.

### Build arguments

If you want to build this image yourself you can set the variables BASEREPO and EPELREPO before running `build.sh` in order to choose a specific "yum mirror" from your local network. Running local builds becomes a lot faster with a mirror around.

This is explained a [bit more here](../docker-base/BUILDARGS.md).

# Instructions

*Most content below is a copy of the original instructions from "smashwilson/lets-nginx".*

Put browser-valid TLS termination in front of any Dockerized HTTP service with one command.

```bash
docker run --detach \
  --name lets-nginx \
  --link backend:backend \
  --env EMAIL=me@email.com \
  --env DOMAIN=myhost.mydomain \
  --env UPSTREAM=backend:8080 \
  --publish 80:80 \
  --publish 443:443 \
  vertigo/lets-nginx
```

Issues certificates from [letsencrypt](https://letsencrypt.org/), installs them in [nginx](https://www.nginx.com/), and schedules a cron job to reissue them monthly.

:zap: To run unattended, this container accepts the letsencrypt terms of service on your behalf. Make sure that the [subscriber agreement](https://letsencrypt.org/repository/) is acceptable to you before using this container. :zap:

## Prerequisites

Before you begin, you'll need:

 1. A [place to run Docker containers](https://getcarina.com/) **with a public IP**. You can read a [quick intro to Carina here](CARINA.md);
 2. A domain name with an *A record* pointing to your cluster. If you own a domain this is easy, just do it. If you don't, you can get one for free on [no-ip.com](www.no-ip.com), there are loads of options available but don't get too picky;
 3. The backend container, i.e. the very service you want to expose with nginx/letsencrypt.

Please understand that letsencrypt requires a public IP to work. Don't be a whiny millenial about it.

## Testing the pre-reqs

* Check the connection to docker cluster (kinda basic)

```
docker version
docker ps
```

* Test if the public IP works at all (noip.com takes some time)

```
ping yourhost.thedomain.youchose
```

* Launch your backend service. Anything will do for a try, like a fast-food nginx with its default home page. For example (as in `backend.sh`):

```bash
docker run --name web-backend -d \
  -p 8000:80 \
  nginx
```

Please note that you obviously **do not need** to expose the backend container port like above - that is the whole point, `vertigo/lets-nginx` will do it for you with HTTPS. For now this is only a convenience - until everything works fine you can always test the backend directly.

So, to test this backend directly you can open the browser on the URL below:

    http://yourhost.thedomain.youchose:8000

When everything is done you will access the same content through `vertigo/lets-nginx` on the URL below:

    https://yourhost.thedomain.youchose

Let us proceed.

## Usage

Launch your backend container and note its name, then launch `vertigo/lets-nginx` with the following parameters:

 * `--link backend:backend` to link your backend service's container to this one. *(This may be unnecessary depending on Docker's [networking configuration](https://docs.docker.com/engine/userguide/networking/dockernetworks/).)*
 * `-e EMAIL=` your email address, used to register with letsencrypt.
 * `-e DOMAIN=` the domain name.
 * `-e UPSTREAM=` the name of your backend container and the port on which the service is listening.
 * `-p 80:80` and `-p 443:443` so that the letsencrypt client and nginx can bind to those ports on your public interface.
 * `-e STAGING=1` uses the Let's Encrypt *staging server* instead of the production one.
            I highly recommend using this option to double check your infrastructure before you launch a real service.
            Let's Encrypt rate-limits the production server to issuing
            [five certificates per domain per seven days](https://community.letsencrypt.org/t/public-beta-rate-limits/4772/3),
            which (as I discovered the hard way) you can quickly exhaust by debugging unrelated problems!
 * `-v {PATH_TO_CONFIGS}:/configs:ro` specify manual configurations for select domains.  Must be in the form {DOMAIN}.conf to be recognized.

### Using more than one backend service

You can distribute traffic to multiple upstream proxy destinations, chosen by the Host header. This is useful if you have more than one container you want to access with https.

To do so, separate multiple corresponding values in the DOMAIN and UPSTREAM variables separated by a `;`:

```bash
-e DOMAIN="domain1.com;sub.domain1.com;another.domain.net"
-e UPSTREAM="backend:8080;172.17.0.5:60;container:5000"
```

## Caching the Certificates and/or DH Parameters

Since `--link`s don't survive the re-creation of the target container, you'll need to coordinate re-creating
the proxy container. In this case, you can cache the certificates and Diffie-Hellman parameters with the following procedure:

Do this once (as in `volumes.sh`):

```bash
docker volume create --name letsencrypt
docker volume create --name letsencrypt-backups
docker volume create --name dhparam-cache
```

## Tasting it (STAGING)

Then start the container, attaching the volumes you just created and linking it to the backend. *Please, try with STAGING=1 initially, just like in `stage.sh`. You have been warned.*

```bash
docker run --detach \
  --name lets-nginx \
  --link web-backend:backend \
  --env EMAIL=me@email.com \
  --env DOMAIN=yourhost.thedomain.youchose \
  --env UPSTREAM=backend:80 \
  --env STAGING=1 \
  --publish 80:80 \
  --publish 443:443 \
  --volume letsencrypt:/etc/letsencrypt \
  --volume letsencrypt-backups:/var/lib/letsencrypt \
  --volume dhparam-cache:/cache \
  vertigo/lets-nginx
```

You can now open your browser at the URL below:

    https://yourhost.thedomain.youchose

The lets-nginx container should be working as a SSL-enabled reverse proxy to the backend service. Please, note that:

* The certificate is still invalid (STAGING=1), as the browser told you
* The UPSTREAM service uses the *exposed* port from the backend, not the *published* port. Actually it makes no sense to publish the backend port (unless you are troubleshooting lets-nginx itself).

## Running it (for real)

If the staging test went well you can now clean up all containers (including the volumes and the backend) and run it for real.

Cleaning up:

```bash
docker stop lets-nginx
docker rm lets-nginx
docker stop web-backend
docker rm web-backend
docker volume rm letsencrypt letsencrypt-backups dhparam-cache
```

Run the backend *without* published ports:

```bash
docker run --name web-backend -d nginx
```

Create the volumes again (for the last time):

```bash
docker volume create --name letsencrypt
docker volume create --name letsencrypt-backups
docker volume create --name dhparam-cache
```

Finally, run `lets-nginx` for real (no staging, as in `runlets.sh`):

```bash
docker run --detach \
  --name lets-nginx \
  --link web-backend:backend \
  --env EMAIL=me@email.com \
  --env DOMAIN=yourhost.thedomain.youchose \
  --env UPSTREAM=backend:80 \
  --publish 80:80 \
  --publish 443:443 \
  --volume letsencrypt:/etc/letsencrypt \
  --volume letsencrypt-backups:/var/lib/letsencrypt \
  --volume dhparam-cache:/cache \
  vertigo/lets-nginx
```

Certificate generation from letsencrypt takes some time. You can follow the logs:

```bash
docker logs -f lets-nginx
```

As long as you do not erase the volumes, start time will never be slow afterwards.

You can now open your browser at the same URL, as below:

    https://yourhost.thedomain.youchose

This time we have a valid certificate and browser will not complain.

We're done and good to go!

## Adjusting Nginx configuration

The entry point of this image processes the `nginx.conf` file in `/templates` and places the result in `/etc/nginx/nginx.conf`. Additionally, the file `/templates/vhost.sample.conf` will be processed once for each `;`-delimited pair of values in `$DOMAIN` and `$UPSTREAM`. The result of each will be placed at `/etc/nginx/vhosts/${DOMAINVALUE}.conf`.

The following variable substitutions are made while processing all of these files:

* `${DOMAIN}`
* `${UPSTREAM}`

For example, to adjust `nginx.conf`, create that file in your new image directory with the [baseline content](templates/nginx.conf) and desired modifications. Within your `Dockerfile` *ADD* this file and it will be used to create the nginx configuration instead.

```docker
FROM bacen/lets-nginx

ADD nginx.conf /templates/nginx.conf
```

Or, even simpler, you can mount a specific file over "/templates/nginx.conf" or "/templates/vhost.sample.conf" with the "--volume" option on `docker run`. It works the same.

## Client-certificates

You can make `vertigo/lets-nginx` require the the HTTPS client to send client certificates for an extra level of security. There are two ways to do it:

* Use an environment variable SSLCLIENTCA containing the CA public key to verify the client certificate.

* Mount a file with the CA public key at "/etc/certs/ca.pem".

Let's say you do have all the certificate files at hand:

* ca.pem : client certificate's CA
* cert.pem : client certificate public key
* key.pem : client certificate private key

Running `lets-nginx` with a ca certificate is easy, there is a sample in `runcalets.sh`:

```bash
SSLCLIENTCA=`cat /tmp/ca.pem`
echo "SSLCLIENTCA:"
echo "$SSLCLIENTCA"
docker run --detach \
  --name lets-nginx \
  --link web-backend:backend \
  --env EMAIL=me@email.com \
  --env DOMAIN=yourhost.thedomain.youchose \
  --env UPSTREAM=backend:80 \
  --env "SSLCLIENTCA=$SSLCLIENTCA" \
  --publish 80:80 \
  --publish 443:443 \
  --volume letsencrypt:/etc/letsencrypt \
  --volume letsencrypt-backups:/var/lib/letsencrypt \
  --volume dhparam-cache:/cache \
  vertigo/lets-nginx
```

The browser will not work this time (unless it has the client certificate installed), but all-mighty "curl" can do the testing for us. Just CURLing the URL below will fail for the lack of the client certificate:

```bash
curl https://yourhost.thedomain.youchose
```

You need to use the client certificate to make it work:

```bash
curl --cert /tmp/cert.pem --key /tmp/key.pem https://yourhost.thedomain.youchose
```

*(please do not keep such things in "/tmp", this is just a sample)*
