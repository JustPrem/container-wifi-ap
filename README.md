# Container WiFi Access Point
A wifi access point designed to run in Docker/Podman.

If this works for you! And you'd like to buy me a £2 coffee (inflation I know) I have a Ko-fi page. (Button below)

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/P5P2LKHM4)


## Want to Contribute? Here's what you can do.
- Please help with formatting this readme, I'm a programmer first :(
- Come across any issues and manage to fix them? Add them to the bottom of this document. (Might make a seperate text file if needed)

We also have a small to-do list:
- [X] Run an Access Point over Podman.
- [X] 2.4GHz connectivity.
- [ ] 5GHz connectivity (might be partially working).

## Yapping Section (Skip for instructions)
### Why?
I put this together to make my home server extend my WiFi connection, [the only one I could find online was 6 years out of date](https://github.com/offlinehacker/docker-ap).

I know there's ways of doing this outside of a container, but I like knowing that I can delete this anytime I want to and not have to reverse changes to my servers dnsmasq, uninstall hostapd and remove nmcli connections.

### What does it do?
It sets up a container using debian:bookworm-slim as the base, installs hostapd, dnsmasq and some iprouting tools, then handles everything without making changes to the hosts networking settings, for example when the host uses dnsmasq already for other reasons.

As the users all you have to worry about is settings the SSID name and Password (and possibly running a couple extra host commands) while also being able to adjust the subnet mask (it uses 192.168.50.X by default).

### Performance?

I've got this running on a Fedora Server using my old gaming PC as the base with an i7-8700 and 32GB of ram with a network card for the wifi interface, the container is using about 0.01% CPU and 1-2MB of Ram on average. Running on the 2.4GHz band (I can't get 5GHz working yet here in the UK) I'm getting nearly my full home network speed of 80mbps down and 40mbps up, you can toggle 5GHz on and it will use channel 36 by default (change it in entrypoint.sh) but I don't know if it will work.

# Instructions!

#### Disclaimer: I'm running this on a Fedora Server using Podman, I believe this should work with docker but I had some issues and read somewhere that Podman provides better access which is important for Networking.

## Get the image:

### Step 0: Check your system supports running as an access point. Look for "AP" in the supported list.
```
iw list | grep -A 10 "Supported interface modes"
```

### Step 1: Clone this repository. (Make sure you're in the directory you want to download to. hint: use cd)
```
git clone https://github.com/JustPrem/container-wifi-ap
```

### Step 2: Build the image, this will create the image locally.
```
sudo podman build -t wifi-ap-image .
```

### Step 3: Run the image. (This is the minimal command needed to run, instructions below)
```
sudo podman run --pull=never -d --network=host --privileged \
  --name wifi-ap \
  -e WIFI_IFACE=wlp4s0 \
  -e ETH_IFACE=enp3s0 \
  -e SSID="MyCustomSSID" \
  -e PASSWORD="MySecretPass" \
  localhost/wifi-ap-image:latest
```

The `pull=never` makes sure that the local image is used, `--network=host` makes the container use the hosts networking and `privilaged` gives it sudo access to modify and use the network.

### Step 4: DEBUGGING!

Check if the access point works and has internet at this point, if something is wrong then below are the things I did to fix stuff.

**Problem**: The interface is already being used, or something something about the wifi access point.

```
# Stops the network manager from using the wifi interface, replace wlp4s0 with your interface.
sudo nmcli dev set wlp4s0 managed no
```

```
# Takes down the wifi interface, the container will launch it itself. replace wlp4s0 with your interface.
sudo ip link set wlp4s0 down
```

**Problem**: Access Point is up, connecting works but no internet?

```
# This enables ip forwarding over ipv4
sysctl -w net.ipv4.ip_forward=1
```

**Problem**: IPtables don't exist or something along those lines? This is because modern servers use a different system called NatTables or something, just enable the old ones on the host.
```
sudo modprobe iptable_nat
sudo modprobe nf_nat
sudo modprobe xt_MASQUERADE

# If this fixed the issue the below makes it permanent.
echo -e "iptable_nat\nnf_nat\nxt_MASQUERADE" | sudo tee /etc/modules-load.d/wifi-ap.conf)
```

### Minimal Options.
- WIFI_IFACE: The network interface used to create the access point.
- ETH_IFACE: The ethernet interface used to get the internet connection.
- SSID: The network name, set this to whatever you'd like.
- PASSWORD: The WiFi password, set this to something strong, at least 8 characters.

### Additional Optional Variables.<br>
##### Add these in the format `-e VAR=VALUE` like in the example above.

- BAND: Sets the WiFi band, setting it to 5 enables 5Ghz on channel 36 (I can't get it working myself) keeping it default or using anything else will keep it at 2.4Ghz on channel 6.

**QUICK WARNING, If you change the default subnet using the variable below, change the gateway to match it!**,
- AP_SUBNET: Set the subnet of the WiFi access point, by default it's 192.168.50.0/24 to avoid collisions with existing subnets.
- AP_GATEWAY: The Access Point gateway (where the server sits on the Acess Points network), by default this is 192.168.50.1.


