FROM debian:bookworm-slim

USER root

RUN apt-get update && \
    apt-get install -y hostapd dnsmasq iproute2 iptables iputils-ping procps iw && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
