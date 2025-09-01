#!/bin/bash
set -e

# Default variables (can be overridden by environment)
WIFI_IFACE="${WIFI_IFACE:-wlp4s0}"
ETH_IFACE="${ETH_IFACE:-enp3s0}"
AP_SUBNET="${AP_SUBNET:-192.168.50.0/24}"
AP_GATEWAY="${AP_GATEWAY:-192.168.50.1}"
SSID="${SSID:-PodmanAP}"
PASSWORD="${PASSWORD:-SuperSecurePassword123}"
BAND="${BAND:-2.4}"  # options: 2.4 or 5

# Set channel and hw_mode based on BAND
if [ "$BAND" = "5" ]; then
    HW_MODE="a"
    CHANNEL="36"
else
    HW_MODE="g"
    CHANNEL="6"
fi

# Set regulatory domain BEFORE touching the interface
iw reg set GB

# Bring interface down/up AFTER reg domain is set
ip link set dev $WIFI_IFACE down
ip link set dev $WIFI_IFACE up

# Generate hostapd.conf
cat > /etc/hostapd/hostapd.conf <<EOF
country_code=GB
interface=${WIFI_IFACE}
driver=nl80211
ssid=${SSID}
hw_mode=${HW_MODE}
channel=${CHANNEL}
#ieee80211d=1
ieee80211n=1
ieee80211ac=1
wmm_enabled=1
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=${PASSWORD}
logger_syslog=-1
logger_syslog_level=1
EOF

# Generate dnsmasq.conf
cat > /etc/dnsmasq.conf <<EOF
interface=${WIFI_IFACE}
dhcp-range=${AP_GATEWAY%.*}.10,${AP_GATEWAY%.*}.100,24h
server=8.8.8.8
server=8.8.4.4
bind-interfaces
log-queries=no
log-dhcp=no
EOF

# Configure IP for WiFi interface
ip addr add "${AP_GATEWAY%.*}.1/24" dev $WIFI_IFACE || true
ip link set dev $WIFI_IFACE up

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Setup NAT
iptables -t nat -A POSTROUTING -o $ETH_IFACE -j MASQUERADE
iptables -A FORWARD -i $ETH_IFACE -o $WIFI_IFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $WIFI_IFACE -o $ETH_IFACE -j ACCEPT

# Start services
hostapd /etc/hostapd/hostapd.conf &
dnsmasq -d -C /etc/dnsmasq.conf
