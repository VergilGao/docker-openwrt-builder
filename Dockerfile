FROM ubuntu:22.04

LABEL maintainer="VergilGao"
LABEL org.opencontainers.image.source="https://github.com/VergilGao/docker-openwrt-builder"

RUN apt-get update && \
    apt-get -y install \
    # 构建 OpenWrt 所需的软件包
        build-essential \
        clang \
        flex \
        bison \
        g++ \
        gawk \
        gcc-multilib \
        gettext \
        git \
        libncurses5-dev \
        libssl-dev \
        python3-distutils \
        rsync \
        unzip \
        zlib1g-dev \
        file \
        wget \
        libelf-dev \
        qemu-utils \
    # gosu
        gosu \
    # cron
        cron

ENV UMASK=002
ENV UID=99
ENV GID=100
ENV DATA_PERM=770
ENV TZ="Asia/Shanghai"
ENV TARGET_NAME="default"
ENV CRON="* * * * *"

RUN mkdir -p /data /config && \
    useradd -s /sbin/nologin complier && \
    chown -R complier /data /config

ADD /scripts/*.sh /opt/scripts/
RUN chmod -R 770 /opt/scripts/

VOLUME [ "/data", "/config" ]

ENTRYPOINT ["/opt/scripts/docker-entrypoint.sh"]
