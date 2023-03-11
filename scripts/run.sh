#!/bin/bash

set -e

start_time=$(date +"%Y%m%d%H%M")

repo_url=`sed '/^url=/!d;s/.*=//' /config/repo`
repo_url=${repo_url-:"https://github.com/openwrt/openwrt"}

repo_branch=`sed '/^branch=/!d;s/.*=//' /config/repo`
repo_branch=${repo_branch-:"openwrt-22.03"}


if [[ ! -d "/data/src" ]]; then
    echo "---no source files found, clone src from ${repo_url};${repo_branch}...---"
    git clone --single-branch -b ${repo_branch} --depth=1 ${repo_url} /data/src
else
    local_repo_url=`git -C /data/src remote -v | grep "fetch" | head -n 1`
    local_repo_url=`echo ${local_repo_url#origin}`
    local_repo_url=`echo ${local_repo_url%(fetch)}`

    local_repo_branch=`git -C /data/src branch | grep "*"`
    local_repo_branch=`echo ${local_repo_branch#\*}`

    if [[ "${repo_url}" != "${local_repo_url}" ]] || [[ "${local_repo_branch}" != "${repo_branch}" ]]; then
        echo "---detected different repo  ${local_repo_url};${local_repo_branch}, backup into /data/src-"$start_time"-bak...---"
        mv /data/src /data/src-"$start_time"-bak
        "---clone src from ${repo_url};${repo_branch}...---"
        git clone --single-branch -b ${repo_branch} --depth=1 ${repo_url} /data/src
    else
        echo "---update src from ${repo_url};${repo_branch}...---"
        git -C /data/src reset . && git -C /data/src restore .
        git -C /data/src pull
    fi
fi

cd /data/src
rm -rf ./bin/targets

[ -e /config/feeds.conf ] && cp -f /config/feeds.conf feeds.conf.default
[ -e /config/part1.sh ] && chmod +x /config/part1.sh && /config/part1.sh && chmod -x /config/part1.sh
./scripts/feeds update -a && ./scripts/feeds install -a
rm -rf ./files && [ -d /config/files ] && cp -r /config/files files
[ -e /config/part2.sh ] && chmod +x /config/part2.sh && /config/part2.sh && chmod -x /config/part2.sh

config_file=/config/build.config

if [ ! -f $config_file ]; then
    echo "no build.config exits, we will make a new build.config for you."
    rm .config
    [ -e /config/seed.config ] && cp -f /config/seed.config .config
    make menuconfig
    rm -f .config.old
    make defconfig
    ./scripts/diffconfig.sh > $config_file
else
    cp -f $config_file .config
    make defconfig
fi

echo "---Complier start at $(date +"%Y-%m-%d %H:%M:%S")---"

mkdir -p /data/logs

make download -j$(nproc)
if [ -e /config/nproc ] && [ -n "$(cat /config/nproc | sed -n "/^[0-9]\+$/p")" ]; then
    make V=s -j$(cat /config/nproc) > /data/logs/make-$start_time.log
else
    make V=s -j1 > /data/logs/make-$start_time.log
fi

firmware_path="/data/firmware-$TARGET_NAME-$start_time"

cd ./bin/targets/*/* && mkdir -p "$firmware_path" && mv ./* "$firmware_path"

echo "---Complier finish at $(date +"%Y-%m-%d %H:%M:%S")---"
