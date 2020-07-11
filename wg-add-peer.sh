#!/bin/bash

if [ $# -eq 0 ]

then

	echo "There are no parameters provided to a command!"

else

	# Check The OS Version
	if [[ -e /etc/debian_version ]]; then
		source /etc/os-release
		OS=$ID
	fi

	# Install Ubuntu Packages
	if [[ $OS = "ubuntu" ]]; then
		apt-get install -y software-properties-common -y
		apt-get install linux-headers-$(uname --kernel-release) -y
		add-apt-repository ppa:wireguard/wireguard -y
		apt-get update -y
		apt-get install wireguard -y
		apt-get install qrencode iptables resolvconf -y 
	fi

	# Initialize Default Variables
	readonly WHICH_INTERFACE="wg0"
	readonly PROFILE_NAME=$3
	readonly SERVER_KEY_PUBLIC=$(wg show ${WHICH_INTERFACE} public-key)

	# Generate New Peer Keys
	echo "--- Generating Client Config For <${PROFILE_NAME}> ---"
	
	mkdir -p profiles/${PROFILE_NAME}

	readonly PEER_KEY_PRIVATE=$(wg genkey)
	readonly PEER_KEY_PUBLIC=$(echo ${PEER_KEY_PRIVATE} | wg pubkey)
	readonly PEER_KEY_PRE_SHARED=$(wg genpsk)

	# Create PEER Private/Public Keys
	echo -e ${PEER_KEY_PRIVATE} >> profiles/${PROFILE_NAME}/${PROFILE_NAME}-privatekey.key
	echo -e ${PEER_KEY_PUBLIC} >> profiles/${PROFILE_NAME}/${PROFILE_NAME}-publickey.pub
	echo -e ${PEER_KEY_PRE_SHARED} >> profiles/${PROFILE_NAME}/${PROFILE_NAME}-preshared.psk

	# Add New Peer
	wg set ${WHICH_INTERFACE} peer ${PEER_KEY_PUBLIC} preshared-key ./profiles/${PROFILE_NAME}/${PROFILE_NAME}-preshared.psk allowed-ips $1/32
	wg-quick save ${WHICH_INTERFACE}

	# Generate New Config File
	cat <<END_OF_CONFIG >> profiles/${PROFILE_NAME}/$3.conf 
[Interface]
Address = $1/24
PrivateKey = $PEER_KEY_PRIVATE
DNS = 1.1.1.1

[Peer]
PublicKey = ${SERVER_KEY_PUBLIC}
PresharedKey = ${PEER_KEY_PRE_SHARED}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $2:51820
END_OF_CONFIG

	# Generate QR-CODE For Profile
	qrencode -t ansiutf8 < profiles/${PROFILE_NAME}/${PROFILE_NAME}.conf
	qrencode -o profiles/${PROFILE_NAME}/${PROFILE_NAME}.png < profiles/${PROFILE_NAME}/${PROFILE_NAME}.conf

	# Compress Config Files & Remove Client Directory Files
	tar czvf profiles/${PROFILE_NAME}.tar.gz profiles/${PROFILE_NAME}
	rm -rf profiles/${PROFILE_NAME}
fi
