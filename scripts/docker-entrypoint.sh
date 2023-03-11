#!/bin/bash

USER=complier

echo "---Setup Timezone to ${TZ}---"
echo "${TZ}" > /etc/timezone
echo "---Checking if UID: ${UID} matches user---"
usermod -u ${UID} ${USER}
echo "---Checking if GID: ${GID} matches user---"
groupmod -g ${GID} ${USER} > /dev/null 2>&1 ||:
usermod -g ${GID} ${USER}
echo "---Setting umask to ${UMASK}---"
umask ${UMASK}

echo "---Taking ownership of data...---"
git config --global core.fileMode false

if [ ! -d /config ]; then
    echo "---no config folder found, create...---"
    mkdir -p /config
fi
if [ ! -f /config/repo ]; then
    echo "---no repo config found, create...---"
    echo -e "url=https://github.com/openwrt/openwrt\nbranch=openwrt-22.03" >> /config/repo
fi

chown -R root:${GID} /opt/scripts
chmod -R 750 /opt/scripts
chown -R ${UID}:${GID} /config
chmod -R ${DATA_PERM} /config
chown ${UID}:${GID} /data

if [ -f /config/custom.sh ]; then
    echo "---run custom.sh as root---"
    chmod +x /config/custom.sh && /config/custom.sh && chmod -x /config/custom.sh
fi

gosu ${USER} /opt/scripts/run.sh
