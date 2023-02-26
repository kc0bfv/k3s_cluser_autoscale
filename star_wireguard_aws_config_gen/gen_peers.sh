#!/bin/bash

umask 077

PEER_CNT=100
SERVER="libby.notmet.net"
NETWORK=10.194.57

if [ ! -f "server_private_key" ]; then
    wg genkey > server_private_key
    wg pubkey < server_private_key > server_public_key
elif [ ! -f "server_public_key" ]; then
    wg pubkey < server_private_key > server_public_key
fi

SERV_PRIVKEY=`cat server_private_key`
SERV_PUBKEY=`cat server_public_key`

function start_server_wg0 {

cat << ENDOFLINE > wg0.conf
[Interface]
PrivateKey = $SERV_PRIVKEY
ListenPort = 51820
Address = $NETWORK.1/24
PreUp = sysctl -w net.ipv4.ip_forward=1
PreUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
ENDOFLINE

}

function start_peers {
cat << ENDOFLINE > all_peers_wg0.sh
#!/bin/bash
ENDOFLINE

chmod 700 all_peers_wg0.sh
}

function end_peers {
cat << ENDOFLINE >> all_peers_wg0.sh

PEER_VAR="PEER_\$1" 
echo "\${!PEER_VAR}"

ENDOFLINE
}


function add_peer {

INDEX="$1"
PEER_PRIVKEY=`wg genkey`
PEER_PUBKEY=`echo $PEER_PRIVKEY | wg pubkey`
PEER_ADDR=`expr 100 + $INDEX`

cat << ENDOFLINE >> "all_peers_wg0.sh"

read -r -d '' PEER_$INDEX <<'ENDOFPEER'
[Interface]
PrivateKey = $PEER_PRIVKEY
ListenPort = 51820
Address = $NETWORK.$PEER_ADDR/32

[Peer]
PublicKey = $SERV_PUBKEY
AllowedIPs = $NETWORK.0/24
Endpoint = $SERVER:51820
ENDOFPEER
ENDOFLINE

cat << ENDOFLINE >> "wg0.conf"

[Peer]
PublicKey = $PEER_PUBKEY
AllowedIPs = $NETWORK.$PEER_ADDR/32
ENDOFLINE

}

start_server_wg0

start_peers

PEER_MAX=`expr $PEER_CNT - 1`
for INDEX in `seq 0 $PEER_MAX`; do
    add_peer $INDEX
done

end_peers
