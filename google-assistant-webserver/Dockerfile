ARG BUILD_FROM=hassioaddons/base:latest
FROM $BUILD_FROM

# Set Shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Setup base
RUN \
    apk add --no-cache --virtual .build-dependencies \
        build-base \
        git \
        linux-headers \
        npm \
        python3-dev

# Install packages
#RUN apt-get update
#RUN apt-get install -y jq tzdata python3 python3-dev python3-pip \
#        python3-six python3-pyasn1 libportaudio2 alsa-utils
#RUN pip3 install --upgrade pip
#RUN pip3 install --upgrade six
#RUN pip3 install --upgrade google-assistant-library google-auth \
#        requests_oauthlib cherrypy flask flask-jsonpify flask-restful \
#        grpcio google-assistant-grpc google-auth-oauthlib
#RUN apt-get remove -y --purge python3-pip python3-dev
#RUN apt-get clean -y
#RUN rm -rf /var/lib/apt/lists/*

# Copy data
#COPY run.sh /
#COPY *.py /

#RUN chmod a+x /run.sh

#ENTRYPOINT [ "/run.sh" ]
