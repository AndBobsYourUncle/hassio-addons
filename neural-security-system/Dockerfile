FROM openvino/ubuntu20_dev:2022.1.0

USER root

RUN apt-get update; \
    apt-get install pkg-config software-properties-common -y --no-install-recommends; \
    add-apt-repository ppa:rmescandon/yq; \
    apt-get install -y --no-install-recommends \
        git \
        wget \
        build-essential gcc make cmake cmake-gui cmake-curses-gui \
        libssl-dev \
        libgflags-dev \
        ffmpeg \
        libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libavresample-dev \
        libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
        libdc1394-22-dev \
        libgtk2.0-dev libgtk-3-dev gnome-devel \
        libcanberra-gtk-module libcanberra-gtk3-module \
        yq && \
    rm -rf /var/lib/apt/lists/*

ENV NO_AT_BRIDGE=1

USER openvino

WORKDIR /home/openvino

RUN git clone https://github.com/opencv/opencv.git

RUN git -C opencv checkout 4.x

RUN mkdir -p opencv_build

WORKDIR /home/openvino/opencv_build

RUN cmake ../opencv

RUN make -j4

USER root

RUN make install

WORKDIR /tmp/dependencies

RUN git clone https://github.com/eclipse/paho.mqtt.c.git && \
    cd /tmp/dependencies/paho.mqtt.c && \
    git checkout v1.3.8 && \
    cmake -Bbuild -H. -DPAHO_ENABLE_TESTING=OFF -DPAHO_BUILD_STATIC=ON \
    -DPAHO_WITH_SSL=ON -DPAHO_HIGH_PERFORMANCE=ON && \
    cmake --build build/ --target install && \
    ldconfig

WORKDIR /tmp/dependencies

RUN git clone https://github.com/eclipse/paho.mqtt.cpp && \
    cd /tmp/dependencies/paho.mqtt.cpp && \
    cmake -Bbuild -H. -DPAHO_BUILD_STATIC=ON && \
    cmake --build build/ --target install && \
    ldconfig

WORKDIR /tmp/dependencies

RUN git clone https://github.com/nadjieb/cpp-mjpeg-streamer.git && \
    cd /tmp/dependencies/cpp-mjpeg-streamer && \
    cmake . && \
    make install

WORKDIR /tmp/dependencies

RUN git clone https://github.com/jbeder/yaml-cpp.git && \
    cd /tmp/dependencies/yaml-cpp && \
    cmake DYAML_BUILD_SHARED_LIBS=ON . && \
    make install

WORKDIR /tmp/dependencies

USER openvino

WORKDIR /home/openvino

RUN git clone https://github.com/WongKinYiu/yolov7.git

WORKDIR /home/openvino/yolov7

RUN wget https://github.com/WongKinYiu/yolov7/releases/download/v0.1/yolov7-tiny.pt

RUN pip3 install -r requirements.txt

RUN python3 export.py --fp16 --weights yolov7-tiny.pt

WORKDIR /home/openvino

RUN omz_downloader --name yolo-v3-tiny-tf && \
    omz_converter --name yolo-v3-tiny-tf

ARG CACHEBUST=1

RUN git clone https://github.com/AndBobsYourUncle/mqtt_neural_system.git

WORKDIR /home/openvino/mqtt_neural_system

RUN git checkout finish && cmake . && make

USER openvino

RUN chmod +x /home/openvino/mqtt_neural_system/start_neural_security_system.sh

CMD [ "/bin/bash", "-c", "/home/openvino/mqtt_neural_system/start_neural_security_system.sh" ]
