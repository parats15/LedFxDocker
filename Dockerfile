# syntax = docker/dockerfile:1.2

FROM python:buster
WORKDIR /app
ARG TAG
RUN pip install Cython
RUN dpkg --add-architecture armhf
RUN apt-get update
RUN apt-get install -y gcc \
                       git \
                       libatlas3-base \
                       libavformat58 \
                       portaudio19-dev \
                       avahi-daemon \
                       pulseaudio \
                       alsa-utils \ 
                       libnss-mdns \
                       wget \
                       libavahi-client3:armhf \
                       libavahi-common3:armhf \
                       apt-utils \
                       libvorbisidec1:armhf \
                       squeezelite \
                       make \
                       autotools-dev \
                       automake \
                       libasound2-dev \
                       libpulse-dev \
                       libjack-dev

RUN adduser root pulse-access
RUN echo '*' > /etc/mdns.allow \
	&& sed -i "s/hosts:.*/hosts:          files mdns4 dns/g" /etc/nsswitch.conf \
	&& printf "[server]\nenable-dbus=no\n" >> /etc/avahi/avahi-daemon.conf \
	&& chmod 777 /etc/avahi/avahi-daemon.conf \
	&& mkdir -p /var/run/avahi-daemon \
	&& chown avahi:avahi /var/run/avahi-daemon \
	&& chmod 777 /var/run/avahi-daemon

RUN pip install --upgrade pip wheel setuptools
RUN pip install lastversion
RUN pip install numpy
RUN pip install git+https://github.com/LedFx/LedFx@$TAG
RUN git clone https://github.com/quiniouben/vban.git /install/vban
RUN cd /install/vban \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install \
    && rm -r /install

WORKDIR /app
ARG TARGETPLATFORM
RUN --mount=type=secret,id=GITHUB_API_TOKEN if [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=armhf; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=armhf; else ARCHITECTURE=amd64; fi \
    && export GITHUB_API_TOKEN=$(cat /run/secrets/GITHUB_API_TOKEN) && lastversion download badaix/snapcast --format assets --filter "^snapclient_(?:(\d+)\.)?(?:(\d+)\.)?(?:(\d+)\-)?(?:(\d)(_$ARCHITECTURE\.deb))$" -o snapclient.deb

RUN apt-get install -fy ./snapclient.deb && rm -rf /var/lib/apt/lists/*
COPY setup-files/ /app/
RUN chmod a+wrx /app/*

ENTRYPOINT ./entrypoint.sh
