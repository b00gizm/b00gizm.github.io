---
layout:     post
title:      "Sunday Hacking: Sonos Home (Part 2)"
author:     Pascal Cremer
date:       2016-08-29 16:19:43
tags:       sonos raspberrypi docker kubernetes devops http api
published:  true
---
*(This is part two of my "Sunday Hacking: Sonos Home" project. Click [here](http://codenugget.co/2016/05/22/sunday-hacking-sonos-home-part1.html) if you haven't read [part one](http://codenugget.co/2016/05/22/sunday-hacking-sonos-home-part1.html) yet)*

Last time, we bootstrapped the inofficial Sonos HTTP API in our single node Kubernetes cluster, running on a Raspberry Pi (RPI) Model 3. Today we'll prepare and secure our setup so that it can be safely accessed from outside (aka "the interwebs").

## Day 2: Outside Access

The requirements for this step: Your own domain

* Get a free subdomain for Dynamic DNS (e.g. [No-IP.com](http://www.noip.com/))
* Or grab [your own domain](https://hover.com/kt4qAv7j) at [Hover](https://hover.com/kt4qAv7j).

Please note: Since most ISPs only provide dynamic home IP addresses, you must ensure that your domain updates its configuration accordingly when necessary.

* [Dynamic DNS Update client](http://www.noip.com/download) from No-IP.com
* [Python script for Dynamic DNS updates](https://github.com/tofumatt/dynamic-dns-on-hover) for Hover

## Building our Nginx Image

The Sonos API is already running a Node.js HTTP server, but today, we'll put an Nginx server right in front of it. [Nginx](http://nginx.org) is a pretty sweet solution, because we can easily add HTTPS/SSL encryption, are able to define routes to multiple services (yet to come) and do some more cool things you'll see in a bit.

But first things first: Let's build an Nginx Docker image for our RPI:

```
FROM resin/rpi-raspbian:jessie
MAINTAINER Pascal Cremer "b00gizm@gmail.com"

RUN apt-get update \
    && apt-get install -yq --no-install-recommends \
        nginx \
    && apt-get autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Nginx configs
COPY rootfs/etc/nginx/nginx.conf          /etc/nginx/nginx.conf
COPY rootfs/etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

# Nginx start script
COPY start-nginx.sh /usr/bin/start-nginx

RUN chmod +x /usr/bin/start-nginx \
    && mkdir -p /etc/nginx/logs \
    && mkdir /usr/share/nginx/logs \
    && ln -sf /dev/stdout /etc/nginx/logs/access.log \
    && ln -sf /dev/stdout /etc/nginx/logs/error.log

EXPOSE 80 443

CMD ["/usr/bin/start-nginx"]
```

There's nothing too exciting here: We take Raspbian Jessie as base, install all necessary packages, then copy some configuration files and a start script, of which we'll talk about in a few minutes, and finally symlink our Nginx logs to `stdout` so we're able to inspect them later via `docker logs`.

The interesting stuff is inside `/etc/nginx/conf.d/default.conf`:

```
server {
    listen  [::]:80;
    listen  80;

    location / {
        root  /usr/share/nginx/html;
    }

    location ~ ^/api(/?)(.*)$ {
        proxy_pass http://%SONOS_HTTP_API_HOST%:%SONOS_HTTP_API_PORT%/$2$is_args$args;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
```

So we define a simple server block for listening to HTTP requests on port 80. Everthing below the `/api` prefix will be proxied to another address, which will consist of host and port of our Sonos HTTP API.

But what about this `%...%` syntax? Well, that's actually a little hack for now. `%SONOS_HTTP_API_HOST%` and `%SONOS_HTTP_API_PORT%` are placeholders for the acutal host and port of our Sonos HTTP API in our Kubernetes cluster. Host and port are determined by the corresponding `sonos-http-api` service at runtime. How may other containers (like our Nginx) know about these? If you've ever used the `--link` flag with `docker run`, you might know the answer: Environment variables. And the `start-nginx` start script will actually take care of replacing `%SONOS_HTTP_API_HOST%` and `%SONOS_HTTP_API_PORT%` with the acutal values of those variables with a pinch of [`sed`](http://www.gnu.org/software/sed/) wizardry:

```bash
#!/usr/bin/env bash

sed -i "s/%SONOS_HTTP_API_HOST%/${SONOS_HTTP_API_SERVICE_HOST}/" /etc/nginx/conf.d/default.conf
sed -i "s/%SONOS_HTTP_API_PORT%/${SONOS_HTTP_API_SERVICE_PORT}/" /etc/nginx/conf.d/default.conf

nginx -g "daemon off;"
```

It's certainly not the most elegant solution and there are much more sophisticated altenatives in the Kubernetes eco system like [SkyDNS](https://github.com/skynetservices/skydns), but for now, let's keep this as simple as possible.

## Updating our Kubernetes Setup

Before we're getting to the actual configuration, let's summarize what we want to achieve:

1. The Kubernetes pod of the Sonos HTTP API needs to run on our host network (our local network) to be able to talk to our Sonos devices

2. We need to define a Kubernetes service for our HTTP API so that we can access it from inside our Nginx container within its pod

3. The service for the Nginx pod (as entry point) must also accessible directly from our host IP (the IP of our Rasbperry Pi)

Phew, that's a handful! I must admit, since this is definitely not a common setup, it took me quite some time to make it work, and there might be better ways to do it, but for now, I'm pretty happy with it:

```yaml
apiVersion: v1
kind: List
items:

- apiVersion: v1
  kind: Pod
  metadata:
    name: nginx
    labels:
      name: nginx
      project: sonos-home
      component: www
  spec:
    containers:
      - name: nginx
        image: "${DOCKER_PREFIX}/nginx"
        imagePullPolicy: IfNotPresent
        ports:
          - {containerPort: 80}
          - {containerPort: 443}
        readinessProbe:
          tcpSocket:
            port: 443

- apiVersion: v1
  kind: Service
  metadata:
    name: nginx
    labels:
      name: nginx
      project: sonos-home
  spec:
    ports:
    - name: http
      port: 80
      protocol: TCP
    - name: https
      port: 443
      protocol: TCP
    selector:
      name: nginx
      component: www
    externalIPs:
      - ${EXTERNAL_IP}

- apiVersion: v1
  kind: Pod
  metadata:
    name: sonos-http-api
    labels:
      name: sonos-http-api
      project: sonos-home
      component: api
  spec:
    hostNetwork: true
    containers:
      - name: sonos-http-api
        image: "${DOCKER_PREFIX}/sonos-http-api"
        imagePullPolicy: IfNotPresent
        ports:
          - {containerPort: 5005}
        readinessProbe:
          tcpSocket:
            port: 5005

- apiVersion: v1
  kind: Endpoints
  metadata:
    name: sonos-http-api
    labels:
      name: sonos-http-api
      project: sonos-home
  subsets:
    - addresses:
      - ip: ${EXTERNAL_IP}
      ports:
      - name: http
        port: 5005
        protocol: TCP

- apiVersion: v1
  kind: Service
  metadata:
    name: sonos-http-api
    labels:
      name: sonos-http-api
      project: sonos-home
  spec:
    ports:
    - name: http
      port: 80
      targetPort: 5005
      protocol: TCP
```

Since the `sonos-http-api` pod uses the `hostNetwork: true` inside its `spec`, we not only have to define our own `Service`, but also our own `Endpoint` set to the `${EXTERNAL_IP}`, which will the the IP of our RPI. By the way, if you're wondering about variables like `${EXTERNAL_IP}` or `${DOCKER_PREFIX}` in our Yaml files: Those will later be "compiled" to real values through a bash script.

The Nginx config is mostly basic stuff, with exception of the `Service`'s `spec` block, containing a single element array `externalIPs` with our `${EXTERNAL_IP}`. With this in place, we can then access our Nginx service right from our host IP on port 80 and (later) 443.

After "compiling" our Yaml template and (re-)creating our Kuberentes setup, we should be greeted with the standard Nginx welcome page when we hit our RPI's IP address in our browser. Awesome! (If you can't wait to try this yourself, please bear with me for instructions right at the end of this post)

## Going HTTPS with Let's Encrypt

Of course, we'd want all the traffic going to our Raspberry Pi to be encrypted. Also, some of the external service which we might use in the course of this series, could require HTTPS for communication. Luckily, it's pretty easy these days to add HTTPS/SSL encrpytion to our Nginx server. Enter [Let's Encrypt](https://letsencrypt.org).

Let's Encrypt is a certificate authorithy for issuing free SSL certificates. Almost all steps are automated, so it's a lot less painful than going through traditional issuers. Giving a full intro to Let's Encrypt would be way out of scope for this tutorial, but there are many good resources on the internet on how to obtain valid SSL certificates though Let's Encrpyt right from your RPI.

Let's Encrypt will generate a bunch of files inside `/etc/letsencrypt`, but those interesting for us are `/etc/letsencrypt/live/yourdomain.tld/{cert,privkey}.pem`. A good pattern would be to symlink these to a folder below the directory of our Nginx `Dockerfile`, which we then have to change to:

```
FROM resin/rpi-raspbian:jessie

...

# Nginx configs
COPY rootfs/etc/nginx/nginx.conf          /etc/nginx/nginx.conf
COPY rootfs/etc/nginx/ssl/                /etc/nginx/ssl/
COPY rootfs/etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

...
```

Here, `rootfs/etc/nginx/ssl` is the subfolder where we'll put or symlink both certificate and private key. During `docker build` both will be copied to the Nginx image.

Please note that this is not the best or most clever solution. SSL certifactes from Let's Encrpyt will expire after 90 days and have to be renewed. With this approach, well have to rebuild our Nginx image (and then restart our Nginx pod) every time we'd renew our certificate. That not a good solution in the long run. We'll come up with something more sophisticated in the near future. But for now, let's keep it like it is.

Finally, we can update our server configuration to:

```
server {
    listen  [::]:443;
    listen  443 ssl;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;

    ...

}

server {
    listen [::]:80;
    listen 80;

    return 301 https://$host$request_uri;
}
```

Now, everything will go through HTTPS. Even HTTP requests will be redirected to their corresponding HTTPS counterpart.

Hitting our RPI's IP address in the browser through HTTPS should result in a warning by your favorite browser vendor -- which is a good sign, because our SSL certificate is tied to a given domain.

![Screenshot](https://raw.githubusercontent.com/b00giZm/b00gizm.github.io/master/uploads/sonos-home-day02-01.png)

When your Domain is configured to point to your router's public IP address and your router is configured to forward traffic from port 80 and 443 to your RPI's internal IP, you should see the real deal.

![Screenshot](https://raw.githubusercontent.com/b00giZm/b00gizm.github.io/master/uploads/sonos-home-day02-02.png)

## Adding Simple HTTP Basic Auth

It would be a pretty bad idea to expose our API to the whole internet without having some kind of protection. Luckily, this is a pretty simple task because of Nginx [support for HTTP Basic Authentication](http://nginx.org/en/docs/http/ngx_http_auth_basic_module.html). Inside our config, we can define a path to a file from where Nginx can read our user credentials.

```
location ~ ^/api(/?)(.*)$ {
    proxy_pass http://%SONOS_HTTP_API_HOST%:%SONOS_HTTP_API_PORT%/$2$is_args$args;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    auth_basic "Protected Realm";
    auth_basic_user_file  /etc/nginx/.htpasswd;
}
```

Here, we define `/etc/nginx/.htpasswd` as path to our credentials file. But, how do we provide this file with our Docker/Kubernetes setup? Of course, we could hard code those credentials into a file and add it from our Dockerfile, but that would be pretty bad, since we don't want those credentials to end up in our version control system.

A better way would be to use [Kubernetes Secrets](http://kubernetes.io/docs/user-guide/secrets/), which are intented to hold sensitive information like passwords, keys or other secruity tokens. Defining a new secret inside our manifest file is actually pretty simple:

```yaml
- apiVersion: v1
  kind: Secret
  metadata:
    name: nginx-basic-secret
    labels:
      name: nginx-basic-secret
      project: sonos-home
  type: Opaque
  data:
    api-user: $(echo "${NGINX_BASIC_AUTH_USER}:${NGINX_BASIC_AUTH_PASS}" | base64)
```

The most significant part is inside the `data` block. Here, we define an entity `api-user`, which, like `EXTERNAL_IP` and `DOCKER_PREFIX` before, will be "compiled" during startup. Kubernetes [expects our secrets to be base64 encoded](http://kubernetes.io/docs/user-guide/secrets/#creating-a-secret-manually), which is why we pipe our output through `base64` at the end. 

We'll put both variables `NGINX_BASIC_AUTH_USER` and `NGINX_BASIC_AUTH_PASS` inside a special file `.env` outside version control, which we'll `source` during startup.

Then, we'll just "mount" our previously defined secret named `nginx-basic-secret` into our Nginx pod:

```yaml
- apiVersion: v1
  kind: Pod
  metadata:
    name: nginx
    ...
  spec:
    containers:
        ...
        volumeMounts:
          - name: http-basic
            mountPath: "/etc/http-basic"
            readOnly: true
    volumes:
      - name: http-basic
        secret:
          secretName: nginx-basic-secret
```

Our `api-user` entity will then be accessible from our Nginx pod from path `/etc/http-basic/api-user`.

Are we done? Well, almost. We have to add the following three lines to our Nginx start script:

```bash
cp /etc/http-basic/api-user /etc/nginx/.htpasswd
chown root:www-data /etc/nginx/.htpasswd
chmod 640 /etc/nginx/.htpasswd
```

This is actually a work around, because `/etc/http-basic/api-user` is only readable by the `root` user and I haven't figured out it it's possible to set permissions inside our Kubernetes manifest (Please let me know if you do).

After restart, our API routes should now be protected via HTTP Basic Auth:

```
λ curl -I --insecure https://192.168.192.29/api/zones
HTTP/1.1 401 Unauthorized
Server: nginx/1.6.2
Date: Mon, 29 Aug 2016 13:55:02 GMT
Content-Type: text/html
Content-Length: 194
Connection: keep-alive
WWW-Authenticate: Basic realm="Protected Realm"
```

## Trying it out for yourself

Since the whole project will be growing even more complex from here on, I've prepared a [repository on Github](https://github.com/b00giZm/sonos-home) for you to clone on your RPI. It contains a start script which will do the heavy lifting for you in just one single command:

`bin/start-k8s.sh`

It will build all docker containers and create a dedicated Kubernetes namespace with all necessary pods, services, and endpoints, so you should be good to go within a few minutes.

```bash
...
[INFO] Reloading namespace sonos-home
namespace "sonos-home" created
pod "nginx" created
service "nginx" created
pod "sonos-http-api" created
endpoints "sonos-http-api" created
service "sonos-http-api" created
[INFO] Waiting for command 'kubectl --namespace=sonos-home get pods --no-headers | (! egrep '0/1')' (retries = 60)
............
[INFO] Command was successful

>> RUNNING!
>>
>> kubectl get po --namespace=sonos-home
>> kubectl get rc --namespace=sonos-home
>> kubectl describe svc --namespace=sonos-home
>>
>> CALL:
>> https://192.168.192.29
```

To tear everything down afterwards, just call `kubectl delete ns sonos-home` from your CLI.

Next time, we'll try out our first little remote Sonos automation and explore the possibilities for adding initial voice control capabilties.
