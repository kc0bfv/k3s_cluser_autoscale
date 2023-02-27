#!/bin/bash

export KUBELET_ARG="--kubelet-arg=provider-id=aws:///$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
export K3S_URL="$(sudo cat /etc/wireguard_host.secret)"
export K3S_TOKEN="$(sudo cat /etc/k3s_master_token.secret)"
export NODE_INDEX="$(curl -s http://169.254.169.254/latest/meta-data/ami-launch-index)"
export NODE_IP="$(sudo bash /etc/wireguard/all_peers_wg0.sh --get-node-ip ${NODE_INDEX})"
export EXTERNAL_IP="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

export INSTALL_K3S_EXEC="${KUBELET_ARG} --node-ip=${NODE_IP} --node-external-ip=${EXTERNAL_IP} --flannel-iface=wg0"

curl -sfL https://get.k3s.io | sh -