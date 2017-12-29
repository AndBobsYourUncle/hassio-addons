# Only works with ARM7 devices such as a Raspberry Pi
FROM multiarch/debian-debootstrap:armhf-stretch

# Install packages
RUN apt-get update \
    && apt-get install -y jq tzdata python3 python3-dev python3-pip \
        python3-six python3-pyasn1 libportaudio2 alsa-utils \
    && pip3 install --upgrade pip \
    && pip3 install --upgrade google-assistant-library google-auth \
        requests_oauthlib cherrypy flask flask-jsonpify flask-restful \
        grpcio google-assistant-grpc google-auth-oauthlib \
    && apt-get remove -y --purge python3-pip python3-dev \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

VOLUME /data

# Copy data
COPY run.sh /
COPY *.py /

RUN chmod a+x /run.sh

# Copy dev client json
COPY client.json /data/client.json

ENTRYPOINT [ "/run.sh" ]
