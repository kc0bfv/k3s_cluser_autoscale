# Star Wireguard AWS Config Generator

This script generates wireguard configuration for a star topology network.

If you provide `server_private_key` and `server_public_key` files it uses those as the hub server's public and private key.  Otherwise it generates them.

Then it uses the hardcoded client count, hub public address, and private network, to produce `wg0.conf` and `all_peers_wg0.sh`.  The former is the hub's wireguard config file.  The latter is a script that, when given a peer index (like you might retrieve on AWS from http://169.254.169.254/latest/meta-data/ami-launch-index) generates the peer's wireguard config.

The idea is - you can bake `all_peers_wg0.sh` into a (PRIVATE!) AMI (perhaps created via Packer), copy wg0.conf onto your server, then bake `setup-wg.service` into your AMI at `/etc/systemd/system/setup-wg.service` and run `systemctl enable setup-wg` on your AMI.
