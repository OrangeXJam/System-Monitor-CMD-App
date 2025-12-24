FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y \
    dialog=1.3-20240101-1 \
    procps \
    util-linux \
    lm-sensors=1:3.6.0-9build1 \
    smartmontools=7.4-2build1 \
    network-manager=1.46.0-1ubuntu2.4 \
    iproute2=6.1.0-1ubuntu6.2 \
    lshw=02.19.git.2021.06.19.996aaad9c7-2build3 \
    dmidecode=3.5-3ubuntu0.1 \
    intel-gpu-tools \
    pciutils=1:3.10.0-2build1 \
    nvidia-utils-550 \
    sudo \
    bc \
    \
    man-db \
    manpages \
    less \
    nano \
    vim \
    \
    # Restore documentation removed by Ubuntu minimization
    && yes | unminimize \
    \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash monitor
RUN echo "monitor ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR /usr/local/bin/ 
COPY mytheme.rc /usr/local/bin/
COPY SM_VE.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/SM_VE.sh

USER monitor

CMD ["/bin/bash", "-c", "exec /usr/local/bin/SM_VE.sh"]
