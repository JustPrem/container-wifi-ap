# Container WiFi Access Point

A lightweight WiFi access point designed to run inside a **Docker/Podman container**.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/P5P2LKHM4)

---

## 📑 Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Why This Project?](#why-this-project)
- [Performance](#performance)
- [Instructions](#instructions)
  - [Step 0: Check Compatibility](#step-0-check-compatibility)
  - [Step 1: Clone Repository](#step-1-clone-repository)
  - [Step 2: Build the Image](#step-2-build-the-image)
  - [Step 3: Run the Container](#step-3-run-the-container)
- [Configuration Options](#configuration-options)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Overview
This project provides a containerized access point using **Debian (bookworm-slim)** as the base.  
It installs and manages `hostapd`, `dnsmasq`, and essential networking tools, without making changes to the host system’s networking.

---

## Features
- ✅ Run an access point with **Podman**  
- ✅ 2.4GHz WiFi connectivity  
- 🚧 Experimental 5GHz support  

---

## Why This Project?
I wanted my home server to double as a WiFi access point, but the only solutions I found online were outdated (e.g., [docker-ap](https://github.com/offlinehacker/docker-ap)).  

Running the AP inside a container means:
- Easy cleanup (just remove the container, no system config to undo).  
- No need to modify the host’s `dnsmasq`, `hostapd`, or `nmcli` settings.  
- Flexible setup — just configure SSID, password, and subnet as needed.  

---

## Performance
Running on:
- **Host**: Fedora Server (i7-8700, 32GB RAM)  
- **WiFi**: Dedicated PCIe card  

Average usage: ~0.01% CPU and 1–2MB RAM.  
On 2.4GHz, speeds reached **80 Mbps down / 40 Mbps up** (close to full ISP speeds).  
5GHz can be toggled (default: channel 36), but may not work reliably.

---

# Instructions!

#### Disclaimer: I'm running this on a Fedora Server using Podman, I believe this should work with docker but I had some issues and read somewhere that Podman provides better access which is important for Networking.

## Get the image:

### Step 0: Check compatibility!
Verify your system supports Access Point (AP) mode. Look for `"AP"` in the supported list:
```bash
iw list | grep -A 10 "Supported interface modes"
```

### Step 1: Clone repository. 
Make sure you're in the directory you want to download to.
```bash
git clone https://github.com/JustPrem/container-wifi-ap
```

### Step 2: Build the image.
This creates the image locally.
```bash
sudo podman build -t wifi-ap-image .
```

### Step 3: Run the container.
This is the minimal setup needed to run the container.
```bash
sudo podman run --pull=never -d --network=host --privileged \
  --name wifi-ap \
  -e WIFI_IFACE=wlp4s0 \
  -e ETH_IFACE=enp3s0 \
  -e SSID="MyCustomSSID" \
  -e PASSWORD="MySecretPass" \
  localhost/wifi-ap-image:latest
```

Notes:
> - `WIFI_IFACE` is the WiFi interface, make sure to use the correct one.
> - `ETH_IFACE` is the Etherned interface, make sure to set the correct one.
> - `pull=never` ensures the local image is used.
> - `network=host` allows the container to share the host's networking.
> - `privileged` grants necessary permissions to modify networking.

### Configuration Options
These are required for the container to run.
- `WIFI_IFACE`: Network interface used to create the access point.  
- `ETH_IFACE`: Ethernet interface used to provide internet.  
- `SSID`: WiFi network name. Set this to whatever you like.  
- `PASSWORD`: WiFi password. Choose a strong password, at least 8 characters.  

### Additional Optional Variables
These can be added using the format `-e VAR=VALUE` to change certain settings in the container.

- `BAND`: Sets the WiFi band. Use `5` to enable 5GHz on channel 36 (experimental). Any other value or default uses 2.4GHz on channel 6.  

> **Quick Warning:** If you change the default subnet below, make sure to adjust the gateway to match!  

- `AP_SUBNET`: Subnet of the WiFi access point. Default: `192.168.50.0/24`.  
- `AP_GATEWAY`: Access Point gateway (where the server sits on the AP network). Default: `192.168.50.1`.

### Troubleshooting

Check if the access point works and has internet at this point, if something is wrong then below are the things I did to fix stuff.

**Problem:** Interface already in use and/or The container crashes with `handle_probe_req: send failed` continuosly. (This resets when the server is restarted)

```bash
# Stops the network manager from using the wifi interface, replace wlp4s0 with your interface.
sudo nmcli dev set wlp4s0 managed no

# Takes down the wifi interface, the container will launch it itself. replace wlp4s0 with your interface.
sudo ip link set wlp4s0 down
```

**Problem:** Clients connect but no internet

```bash
# This enables ip forwarding over ipv4
sysctl -w net.ipv4.ip_forward=1
```

**Problem:** Missing IPTables modules (common on modern distros)
```bash
sudo modprobe iptable_nat
sudo modprobe nf_nat
sudo modprobe xt_MASQUERADE

# If this fixed the issue the below makes it permanent.
echo -e "iptable_nat\nnf_nat\nxt_MASQUERADE" | sudo tee /etc/modules-load.d/wifi-ap.conf)
```

## Contributing

Contributions are welcome! Here are some ways you can help:

- 🖋️ Improve README formatting, clarity, and instructions  
- 🐛 Submit bug fixes or troubleshooting tips  
- 📋 Add or update items in the [to-do list](#features)  

Please follow standard GitHub workflow: fork the repository, create a branch, make your changes, and submit a pull request. Clear commit messages and descriptive PRs are appreciated!
