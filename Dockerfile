# Start from the base image
FROM debian:bookworm-slim

ENV SWAN_VER=5.1
ENV SING_VER=
WORKDIR /opt/src

# Install dependencies
RUN apt-get -yqq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -yqq --no-install-recommends install \
    wget dnsutils openssl ca-certificates kmod iproute2 \
    gawk net-tools iptables bsdmainutils libcurl3-nss \
    libnss3-tools libevent-dev uuid-runtime xl2tpd \
    libnss3-dev libnspr4-dev pkg-config libpam0g-dev \
    libcap-ng-dev libcap-ng-utils libselinux1-dev \
    libcurl4-nss-dev flex bison gcc make

# Install Libreswan
RUN wget -t 3 -T 30 -nv -O libreswan.tar.gz \
    "https://github.com/libreswan/libreswan/archive/v${SWAN_VER}.tar.gz" || \
    wget -t 3 -T 30 -nv -O libreswan.tar.gz \
    "https://download.libreswan.org/libreswan-${SWAN_VER}.tar.gz" && \
    tar xzf libreswan.tar.gz && \
    rm -f libreswan.tar.gz && \
    cd "libreswan-${SWAN_VER}" && \
    printf 'WERROR_CFLAGS=-w -s\nUSE_DNSSEC=false\nUSE_SYSTEMD_WATCHDOG=false\n' > Makefile.inc.local && \
    printf 'USE_DH2=true\nUSE_NSS_KDF=false\nFINALNSSDIR=/etc/ipsec.d\nNSSDIR=/etc/ipsec.d\n' >> Makefile.inc.local && \
    make -s base && \
    make -s install-base && \
    cd /opt/src && \
    rm -rf "/opt/src/libreswan-${SWAN_VER}" && \
    apt-get -yqq remove \
    libnss3-dev libnspr4-dev pkg-config libpam0g-dev \
    libcap-ng-dev libcap-ng-utils libselinux1-dev \
    libcurl4-nss-dev flex bison gcc make && \
    apt-get -yqq autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/log/* && \
    update-alternatives --set iptables /usr/sbin/iptables-legacy

# Install Sing-box using the .deb package
RUN wget -t 3 -T 30 -nv -O sing-box.deb \
    "https://github.com/SagerNet/sing-box/releases/download/v${SING_VER}/sing-box_${SING_VER}_linux_amd64.deb" && \
    dpkg -i sing-box.deb && \
    rm -f sing-box.deb && \
    mkdir -p /etc/sing-box

# Copy IKEv2 setup script
RUN wget -t 3 -T 30 -nv -O /opt/src/ikev2.sh \
    https://github.com/hwdsl2/setup-ipsec-vpn/raw/9a625dba296d488f89c2213627931b8685efd354/extras/ikev2setup.sh && \
    chmod +x /opt/src/ikev2.sh && \
    ln -s /opt/src/ikev2.sh /usr/bin

# Copy the run.sh script
COPY run.sh /opt/src/run.sh
RUN chmod 755 /opt/src/run.sh

EXPOSE 500/udp 4500/udp

CMD ["/opt/src/run.sh"]

# Metadata
ARG BUILD_DATE
ARG VERSION
ARG VCS_REF
ENV IMAGE_VER=$BUILD_DATE

LABEL maintainer="Mohsen Khoshnevis <khoshnevisit@gmail.com>" \
    org.opencontainers.image.created="$BUILD_DATE" \
    org.opencontainers.image.version="$VERSION" \
    org.opencontainers.image.revision="$VCS_REF" \
    org.opencontainers.image.authors="Mohsen Khoshnevis <khoshnevisit@gmail.com>" \
    org.opencontainers.image.title="IPsec-to-Sing-Box VPN Server on Docker" \
    org.opencontainers.image.description="Docker image to run an IPsec-to-Sing-box VPN server, with IPsec/L2TP, Cisco IPsec and IKEv2." \
    org.opencontainers.image.url="https://github.com/hwdsl2/docker-ipsec-vpn-server" \
    org.opencontainers.image.source="https://github.com/hwdsl2/docker-ipsec-vpn-server" \
    org.opencontainers.image.documentation="https://github.com/hwdsl2/docker-ipsec-vpn-server"
