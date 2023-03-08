packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "wireguard_host" {
  default = "10.194.57.1"
}

source "amazon-ebs" "debian" {
  ami_name      = "k3s-wireguard-node-initial-${formatdate("YYYYMMDD-hhmmss'T'ZZZ", timestamp())}"
  instance_type = "t2.micro"
  region        = "us-east-2"
  source_ami_filter {
    filters = {
      name                = "debian-11-amd64-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "admin"
}

build {

  sources = [
    "source.amazon-ebs.debian"
  ]

  provisioner "file" {
    source      = "all_peers_wg0.sh"
    destination = "/home/admin/all_peers_wg0.sh"
  }

  provisioner "file" {
    source      = "setup-wg.service"
    destination = "/home/admin/setup-wg.service"
  }

  provisioner "shell" {
    environment_vars = [

    ]
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y wireguard wireguard-tools",

      // Setup the wireguard config generator
      "sudo mv /home/admin/all_peers_wg0.sh /etc/wireguard/all_peers_wg0.sh",
      "sudo chown root.root /etc/wireguard/all_peers_wg0.sh",
      "sudo chmod 0500 /etc/wireguard/all_peers_wg0.sh",

      // Setup the wireguard config generator service
      "sudo mv /home/admin/setup-wg.service /etc/systemd/system/setup-wg.service",
      "sudo chown root.root /etc/systemd/system/setup-wg.service",
      "sudo chmod 0644 /etc/systemd/system/setup-wg.service",

      // Enable wireguard
      "sudo systemctl enable setup-wg.service",
      //"sudo systemctl start setup-wg.service",
      "sudo systemctl enable wg-quick@wg0.service",
      //"sudo systemctl start wg-quick@wg0.service",

      // Prep for k3s install in user_data startup script
      "echo 'https://${var.wireguard_host}:6443' | sudo tee /etc/wireguard_host.secret",
      "echo '${var.k3s_master_token}' | sudo tee /etc/k3s_master_token.secret",
      "sudo chmod 400 /etc/wireguard_host.secret",
      "sudo chmod 400 /etc/k3s_master_token.secret"
    ]
  }
}