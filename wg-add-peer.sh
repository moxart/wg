#!/bin/bash

if [ $# -eq 0 ]
then
	echo "There are no parameters provided to a command!"
else

	# Initialize Default Variables
	readonly WHICH_INTERFACE="wg0"
	readonly PROFILE_NAME=$3
	readonly SERVER_KEY_PUBLIC=$(wg show ${WHICH_INTERFACE} public-key)


	# Generate New Peer Keys
	readonly PEER_KEY_PRIVATE=$(wg genkey)
	readonly PEER_KEY_PUBLIC=$(echo ${PEER_KEY_PRIVATE} | wg pubkey)

	# Create PEER Private/Public Keys
	echo -e $PEER_KEY_PRIVATE >> $3-privatekey
	echo -e $PEER_KEY_PUBLIC >> $3-publickey

	# Add New Peer
	wg set ${WHICH_INTERFACE} peer ${PEER_KEY_PUBLIC} allowed-ips $1

	# Generate New Config File
	echo -e "[Interface]\n" >> $3.conf
	echo Address = $1 >> $3.conf
	echo PrivateKye = $PEER_KEY_PRIVATE >> $3.conf
	echo -e "DNS = 1.1.1.1\n" >> $3.conf
	
	echo -e "[Peer]\n" >> $3.conf
	
	echo PublicKey = ${SERVER_KEY_PUBLIC} >> $3.conf
	echo AllowedIPs = 0.0.0.0/0, ::/0 >> $3.conf
	echo Endpoint = $2:51820 >> $3.conf
fi
