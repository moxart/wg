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

	# Initialize Default Variables
	readonly WHICH_INTERFACE="wg0"
	readonly PROFILE_NAME=$3
	readonly SERVER_KEY_PUBLIC=$(wg show ${WHICH_INTERFACE} public-key)

	echo ${PROFILE_NAME}

	# Generate New Peer Keys
	readonly PEER_KEY_PRIVATE=$(wg genkey)
	readonly PEER_KEY_PUBLIC=$(echo ${PEER_KEY_PRIVATE} | wg pubkey)
	readonly PEER_KEY_PRE_SHARED=$(wg genpsk)

	# Create PEER Private/Public Keys
	echo -e ${PEER_KEY_PRIVATE} >> $3-privatekey.key
	echo -e ${PEER_KEY_PUBLIC} >> $3-publickey.pub
	echo -e ${PEER_KEY_PRE_SHARED} >> $3-preshared.psk

	# Add New Peer
	wg set ${WHICH_INTERFACE} peer ${PEER_KEY_PUBLIC} preshared-key ./${PROFILE_NAME}-preshared.psk allowed-ips $1/32
	wg-quick save ${WHICH_INTERFACE}

	# Generate New Config File
	echo -e "[Interface]\n" >> $3.conf
	echo Address = $1/24 >> $3.conf
	echo PrivateKey = $PEER_KEY_PRIVATE >> $3.conf
	echo -e "DNS = 1.1.1.1\n" >> $3.conf
	
	echo -e "[Peer]\n" >> $3.conf
	echo PublicKey = ${SERVER_KEY_PUBLIC} >> $3.conf
	echo PresharedKey = ${PEER_KEY_PRE_SHARED} >> $3.conf
	echo AllowedIPs = 0.0.0.0/0, ::/0 >> $3.conf
	echo Endpoint = $2:51820 >> $3.conf
fi

