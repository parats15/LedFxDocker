[![Docker Pulls](https://img.shields.io/docker/pulls/shirom/ledfx.svg?style=for-the-badge&logo=github)](https://hub.docker.com/repository/docker/shirom/ledfx)

# LedFxDocker
A Docker Image for [LedFx](https://github.com/LedFx/LedFx.git). 

## Introduction
Compiling LedFx to run on different systems is difficult because of all the dependencies. It's especially difficult on a Raspberry Pi (building LedFx on ARM takes over 2 hours). This image has everything built for you, and it can get audio from a [Snapcast server](https://github.com/badaix/snapcast), a [named pipe](https://www.linuxjournal.com/article/2156) or [Vban](https://vb-audio.com/Voicemeeter/vban.htm).

## Supported Architectures
This image supports `x86-64`, `arm` and `arm64`. Docker will automatically pull the appropriate version. 

## Tags 
Tag | Description 
--- | -------- 
`latest` | The master branch of LedFx. 
`frontend_beta` | The frontend_beta branch of LedFx. 

Feel free to open an issue if either of these is out of date

## Setup
### docker-compose.yml
```
version: '3'

services:
  ledfx:
    image: shirom/ledfx 
    container_name: ledfx
    environment: 
      - HOST=192.168.0.15
      - FORMAT=-r 44100 -f S16_LE -c 2
      - SQUEEZE=1
    ports:
      - 8888:8888
    volumes:
      - ~/ledfx-config:/app/ledfx-config
      - ~/audio:/app/audio
```

You can add support for network discovery by adding `network_mode: host`. See [use host networking](https://docs.docker.com/network/host/) for more information. Adding this can break compatibilty on Windows and Mac. 

### Volumes

Volume | Function 
--- | -------- 
`/app/ledfx-config` | This is where the LedFx configuration files are stored. Most people won't need to change anything here manually, so feel free to use a [named volume](https://stackoverflow.com/questions/43248988/how-do-named-volumes-work-in-docker).
`/app/audio` | This folder contains a [named pipe](https://www.linuxjournal.com/article/2156) called `stream` that you can write audio data to. This can be connected to Mopidy, FFmpeg, system audio, or more. See [Sending Audio](#sending-audio) for more information. This volume doesn't need to be set if the `FORMAT` environment variable isn't set. 

### Environment Variables
Each variable corresponds to a different input method. One of the following variables must be set to send audio into the container (or you can set all of them). 

Variable | Function
--- | --------
`HOST` | This is the IP of the Snapcast server. Keep in mind that this IP is resolved from inside the container unless you use [host networking](https://docs.docker.com/network/host/). To refer to other docker containers in [bridge networking](https://docs.docker.com/network/bridge/) (the default for any two containers in the same compose file), just use the name of the container. To refer to `127.0.0.1` use `host.docker.internal` (compatibilty varies greatly between platforms and versions). 
`FORMAT` | This variable specifies the format of the audio coming into `/app/audio/stream`. It can use any of the options defined in [aplay](https://linux.die.net/man/1/aplay). The example shown above corresponds to 44100hz, 16 bits, and 2 channels, the default for most applications. 
`SQUEEZE` | Setting this variable to `1` allows this image to act as a [squeezelite](https://github.com/ralph-irving/squeezelite) client that can connect to a [Logitech Media Server](https://mysqueezebox.com/download).

## Sending Audio

The trickiest part of using this image is getting audio into it. Dealing with audio device drivers is pretty painful; so much so that I spent 20 minutes getting LedFx installed and 50 hours squashing audio bugs. Don't worry, that work has already been done, so here are four approaches to get audio into the container:

### Snapcast

[Snapcast](https://github.com/badaix/snapcast) is a server for playing music synchronously to multiple devices. This image can act as a snapclient device and connect to a snapserver simply by setting the `HOST` environment variable, but you need to get audio into Snapcast too. 

Fundamentally, Snapcast's server gets its audio from a named pipe. This is where option two comes in; you can send audio directly into this image using its named pipe. Snapcast is useful if you have multiple speakers you want to connect to, you already have a snapserver, or you want to send audio from a separate device and have it play in both LedFx and over the system speaker out (`phone -> raspberry pi running Snapcast and LedFx -> speakers`). 

### Named Pipe

This is a great approach if you just want to play system audio or if you're connecting it to some other audio service, and you don't need the extra bloat from Snapcast. Because this image receives data just like a snapserver, any tutorial you find for getting audio into a snapserver will work with this image. [Setup of audio players/server](https://github.com/badaix/snapcast/blob/master/doc/player_setup.md) provides instructions on how to connect Mopidy, FFmpeg, PulseAudio, Airplay, Spotify, VLC, and more. 

To play system audio, you could use Docker's `--device` flag or use FFmpeg to record system audio and send it to the pipe. 

If you want to use a method not mentioned here or one that doesn't have an explicit named pipe option, your easiest method would probably be playing the audio on the system; then use a tool like FFmpeg or PulseAudio to record the system's audio and send it to the container. 

Check out the `examples/` folder for ideas. Once you've completed your setup, consider sharing your compose file; I'm always looking for new examples to add. 

### Logitech Media Server

You can send in audio from a [Logitech Media Server](https://mysqueezebox.com/download). You'll need to set the environment variable `SQUEEZE=1`. There's a docker example of this in the `examples/` folder. To connect, simply setup your Logitech Media Server on the same network as this container, and your server will automatically detect the LedFx as a client and provide an option to connect. If your media server is on a different network or is not detecting LedFx, you can configure `squeeze.conf` in the `setup-files/` folder and build the container locally.

### Balena Sound

[balenaSound](https://github.com/balenalabs/balena-sound) is a Snapserver that's already connected to Bluetooth, Airplay, Spotify, and UPNP that's very easy to set up. Unfortunately, you have to be fully integrated into Balena's system to use it. This means deploying on balenaOS and using Balena's build tools. However, I've integrated this image into their ecosystem, so it will run alongside balenaSound on the same device. 

Just click the button below to deploy it!

[![balena deploy button](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/ShiromMakkad/LedFx-balenaSound)

See [LedFx-balenaSound](https://github.com/ShiromMakkad/LedFx-balenaSound) for hardware requirements and other information. 

You could also run a standalone instance of balenaSound on one device, LedFx on another device, and connect the two using the `HOST` environment variable. 

### Vban

You can send audio directly from Vban, you can use [Voicemeeter-Vban](https://vb-audio.com/Voicemeeter/vban.htm).
You'll need to set the environment variable VBAN_HOST to your Vban IP sender instance VBAN_PORT with sender port default `VBAN_PORT=6980`
and VBAN_STREAMNAME default `VBAN_STREAMNAME=Stream1`

## Support Information
- Shell access while the container is running: `docker exec -it ledfx /bin/bash`
- Logs: `docker logs ledfx`

## Todo
- Add a Mopidy example
- Add an example using `--device`
- Check if a direct connection to the PulseAudio server works. [Example](https://github.com/balenablocks/audio#sendreceive-audio). 

## Building Locally

If you want to make local modifications to this image for development purposes or just to customize the logic:
```
git clone https://github.com/ShiromMakkad/LedFxDocker.git
cd LedFxDocker
docker build -t shirom/ledfx .
```
To build for `x86-64` and `arm` use:

`docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 --tag shirom/ledfx --output type=image,push=false .`

Keep in mind, this command takes over 2 hours to finish for `arm` because of the `aubio` installation.

If you're looking for ways to contribute, check the TODO or contribute to `examples/`. 
