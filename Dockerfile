ARG BASE_IMAGE
## BASE_IMAGE is image from ubuntu:18.04

### 1st stage
FROM node:12 AS novnc

# noVNC with chrome77 workaround patch
RUN git clone https://github.com/phcapde/noVNC.git /novnc

WORKDIR /novnc
ADD novnc.patch .
RUN patch -p1 < novnc.patch
RUN  npm install && \
    ./utils/use_require.js --as commonjs --with-app --clean

### last stage
WORKDIR /
FROM ${BASE_IMAGE}
#FROM ubuntu:18.04

LABEL maintainer="YoheiKakiuchi <youhei@jsk.imi.i.u-tokyo.ac.jp>"

ENV DISPLAY ":0"

ENV DEBIAN_FRONTEND noninteractive

## original image.tar.gz
# https://bintray.com/tigervnc/stable/download_file?file_path=tigervnc-1.10.1.x86_64.tar.gz

RUN apt-get update && \
    apt-get install --no-install-recommends -y curl ca-certificates fluxbox xfonts-base xauth x11-xkb-utils xkb-data dbus-x11 python3 python3-pip supervisor && \
    curl -L https://altushost-swe.dl.sourceforge.net/project/tigervnc/stable/1.10.1/tigervnc-1.10.1.x86_64.tar.gz | tar xz --strip 1 -C / && \
    pip3 install -U setuptools wheel && \
    pip3 install -U websockify && \
    apt-get remove -y python3-pip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=novnc /novnc/build /novnc

COPY . /app

RUN cp /app/index.html /novnc/

VOLUME /tmp/.X11-unix

EXPOSE 80

CMD ["supervisord", "-c", "/app/supervisord.conf"]