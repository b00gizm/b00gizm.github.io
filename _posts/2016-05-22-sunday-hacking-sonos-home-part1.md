---
layout:     post
title:      "Sunday Hacking: Sonos Home (Part 1)"
author:     Pascal Cremer
date:       2016-05-22 18:27:14
tags:       sonos raspberrypi docker kubernetes devops http api
published:  true
---
I'm really intrigued by IoT devices like the [Amazon Echo](http://www.amazon.com/Amazon-Echo-Bluetooth-Speaker-with-WiFi-Alexa/dp/B00X4WHP5E) or, most recently, [Google Home](https://home.google.com/) from this year's [Google I/O](https://events.google.com/io2016/). The idea of talking to a device and saying, "Play my morning playlist in the kitchen!" would be a nerd's dream come true for me. But since I live in Germany, I've just given up hope being able to buy one of those devices in the near future (or waiting for Apple to make something comparable).

I've got all those [Sonos](http://www.sonos.com/) speakers scattered around the house and, even though not officially supported, there are ways to access the controller's API. So let's get our hands dirty and build our own Echo/Home device for controlling Sonos with our voice.

Since this will certainly be a bigger project, I'll be spreading the tutorial across different blogs posts.

*(Disclaimer: I'll be touching quite a few advanced topics in the couse of this tutorial. If you're more of a beginner, this just might not be the best starting point for you.)*

## Day 1: A Sonos HTTP API

The hardware requirements for this step:

* One (or more) Sonos speakers (starting $199)
* A Raspberry Pi 3 ($40)
* An SD Card (16GB recommended; around $8)
* A computer for flashing the SD

## Preparing your Raspberry Pi

I recently got this new [Raspberry Pi (RPI) 3 Model B](https://www.raspberrypi.org/products/raspberry-pi-3-model-b/) with certainly the [most awesome case](https://www.raspberrypi.org/blog/lego-nespi-case/) available. So let's load it up with some container goodness.

The best and easiest option for running Docker on your RPI might be [HypriotOS](http://blog.hypriot.com/), which is just a minimal Debian-based OS optimized for and loaded with a recent version of Docker. You can download [ready-to-use images](http://blog.hypriot.com/downloads/) to flash onto your RPI's SD card right from their website. Just follow their ["Getting Started" guide](http://blog.hypriot.com/getting-started-with-docker-on-your-arm-device/) and you should be good to go within minutes.

```bash
pi@raspberrypi ~
λ docker version
Client:
 Version:      1.10.3
 API version:  1.22
 Go version:   go1.4.3
 Git commit:   20f81dd
 Built:        Thu Mar 10 22:23:48 2016
 OS/Arch:      linux/arm

Server:
 Version:      1.10.3
 API version:  1.22
 Go version:   go1.4.3
 Git commit:   20f81dd
 Built:        Thu Mar 10 22:23:48 2016
 OS/Arch:      linux/arm
```

## Installing Kubernetes

We could run all Docker containers we'll be creating in the course of this tutorial manually, or could use some kind of container management. My tool of choice is [Kubernetes](http://kubernetes.io/) by Google, mostly because I'm using it [on a daily basis at my job at Chefkoch](https://speakerdeck.com/b00gizm/2016), I know how to get stuff done with it, and I've grown to really like it ;)

If you don't know Kubernetes at all, just think of it as a managed Environment for running containers. Containers are running in Kubernetes [pods](http://kubernetes.io/docs/user-guide/pods/) and can be accessed via Kubernetes [services](http://kubernetes.io/docs/user-guide/services/). If containers crash or go down, Kubernetes will try its best to bring them back up automatically. For more, please refer to the [official Kubernetes docs](http://kubernetes.io/docs/).

Installing all components for bootstrapping a single node Kubernetes cluster can be a bit tedious. Luckily, there is the [k8s-on-rpi](https://github.com/awassink/k8s-on-rpi) repo on Github, which makes it a one liner in your terminal. Well, almost. I had to make a [few](59a66742fe40dafd93e093b38dfc39e705fc4f8c) [adjustments](192d0459d51177c73c7a4d09d2d46d71527cbb22) to make it work on my RPI 3 Model B with Docker 1.10, which I'll be using in the following steps.

```bash
λ curl -L -o k8s-on-rpi.zip https://github.com/b00gizm/k8s-on-rpi/archive/master.zip
λ unzip k8s-on-rpi.zip
λ cd k8s-on-rpi
λ sudo ./install-k8s-master.sh
```

This will download a bunch of Docker images with all necessary components for running a Kubernetes master node on your RPI. It will also install some system services that'll bring the node with all its pods and services back up automatically after a reboot.

When you know hit `docker ps` inside your terminal, there should be a bunch of containers running:

```bash
λ docker ps
CONTAINER ID        IMAGE                                           COMMAND                  CREATED             STATUS              PORTS               NAMES
2bb5a414f367        gcr.io/google_containers/hyperkube-arm:v1.1.2   "/hyperkube controlle"   2 minutes ago       Up 2 minutes                            k8s_controller-manager.7042038a_k8s-master-127.0.0.1_default_43160049df5e3b1c5ec7bcf23d4b97d0_3be37290
30a29c192241        gcr.io/google_containers/hyperkube-arm:v1.1.2   "/hyperkube scheduler"   2 minutes ago       Up 2 minutes                            k8s_scheduler.d905fc61_k8s-master-127.0.0.1_default_43160049df5e3b1c5ec7bcf23d4b97d0_7a5ea21c
604bc2626bd4        gcr.io/google_containers/hyperkube-arm:v1.1.2   "/hyperkube apiserver"   2 minutes ago       Up 2 minutes                            k8s_apiserver.f4ad1bfa_k8s-master-127.0.0.1_default_43160049df5e3b1c5ec7bcf23d4b97d0_6ff9a9e2
39790d8ece99        gcr.io/google_containers/pause-arm:2.0          "/pause"                 2 minutes ago       Up 2 minutes                            k8s_POD.d853e10f_k8s-master-127.0.0.1_default_43160049df5e3b1c5ec7bcf23d4b97d0_0b3708d3
eb5791fc2810        gcr.io/google_containers/hyperkube-arm:v1.1.2   "/hyperkube proxy --m"   2 minutes ago       Up 2 minutes                            k8s-master-proxy
817c5a053351        gcr.io/google_containers/hyperkube-arm:v1.1.2   "/hyperkube kubelet -"   2 minutes ago       Up 2 minutes                            k8s-master
```

Yay, we just made our RPI a fully fledged Kubernetes node.

# The Actual Sonos HTTP API

Now that we have all pieces in place, let's get to the real stuff: Although Sonos does not offer an official API, behind the curtains, it's just good ol' [SOAP](https://en.wikipedia.org/wiki/SOAP). So, it's not that hard to reverse engineer it. In fact, some people [already](https://github.com/gotwalt/sonos) [did](https://github.com/SoCo/SoCo). Big Kudos to them!

Last week, I stubled across the awesome [node-sonos-http-api](https://github.com/jishi/node-sonos-http-api) repository, which offers a pretty extensive HTTP API for controlling the Sonos system on your local network. It even includes a Dockerfile for running the API inside a Docker container. Of course, we cannot just use it as-is, because our RPI is powered by ARM and we need at least some custom base images built for ARM. Luckily [the Hypriot guys thought about that](https://hub.docker.com/u/hypriot/) too.

So here's my customized version, which uses the [`hypriot/rpi-node`](https://hub.docker.com/r/hypriot/rpi-node/) image as base:

```Docker
FROM hypriot/rpi-node:6.1-slim
MAINTAINER Pascal Cremer "b00gizm@gmail.com"

ENV GIT_TAG=master
ENV GIT_SOURCE="https://github.com/jishi/node-sonos-http-api/archive/${GIT_TAG}.zip"

{% gist cc704ba2a96e4a319e9e %}[^gist]

RUN apt-get update \
    && apt-get install -yq --no-install-recommends \
        curl \
        unzip \
    && curl -L -o node-sonos-http-api.zip ${GIT_SOURCE} \
    && mkdir -p /srv \
    && unzip node-sonos-http-api.zip \
    && mv node-sonos-http-api-${GIT_TAG} /code \
    && cd /code \
    && npm install --production \
    && apt-get autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /code

EXPOSE 3500 5005

CMD ["npm", "start"]
```

So let's build and run it:

```bash
λ cd /path/to/Dockerfile
λ docker build -t sonos-http-api .
λ docker run -d --net=host sonos-http-api
```

Take note of the `--net=host` flag, which basically means to not containerize the container's networking, which, in this case, is necessary for the API to find the Sonos system on the same local network as your RPI.

If everything is working as expected, you should be able to `curl http://localhost:5005/zones` from your RPI and receive a valid response, listing all your Sonos devices on the network.

Our last excercise for today is to run the HTTP API in a pod on our Kubernetes node. It's actually quite easy. Create a file named `app.yml` and paste in the following contents:

```yaml
apiVersion: v1
kind: List
items:

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
        image: sonos-http-api
        imagePullPolicy: IfNotPresent
        ports:
          - {containerPort: 5005}
        readinessProbe:
          tcpSocket:
            port: 5005
```

If you're familiar with Kubernetes, this is mostly just your common boilerplate for creating a pod. If you're new to Kubernetes, just ignore the `metadata` section for now. The interesting part is the `spec` section, which basically is just the `docker run` command from above "translated" to Kubernetes' config format with an additional check called `readinessProbe`. This probe will notify the system when the container inside the pod is ready to respond to requests on TCP port `5005`.

Now create the pod in the default namespace:

```bash
λ cd /path/to/yml
λ kubectl create -f app.yml
pod "sonos-http-api" created
```

And after a few seconds, it should be up and running:

```bash
λ kubectl get po
NAME                   READY     STATUS    RESTARTS   AGE
k8s-master-127.0.0.1   3/3       Running   6          8h
sonos-http-api         1/1       Running   0          10s
```

Try to access the `zones` API endpoint in your browser by directly pointing it to your RPI's IP address with port `5005`:

![Screenshot](https://raw.githubusercontent.com/b00giZm/b00gizm.github.io/master/uploads/sonos-home-day01.png)

So let's review what we did today: We took a "vanilla" RPI and transformed it into a single node Kubernetes cluster running a fully-fledged HTTP API to access and control the Sonos speakers on our local network. Not that bad for a start.

Next time, we'll expand our Kubernetes setup and bring Nginx into the mix to secure our API for access outside our local network.
