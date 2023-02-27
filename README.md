# Star Wireguard AWS Config Generator

This script generates wireguard configuration for a star topology network.

If you provide `server_private_key` and `server_public_key` files it uses those as the hub server's public and private key.  Otherwise it generates them.

Then it uses the hardcoded client count, hub public address, and private network, to produce `wg0.conf` and `all_peers_wg0.sh`.  The former is the hub's wireguard config file.  The latter is a script that, when given a peer index (like you might retrieve on AWS from http://169.254.169.254/latest/meta-data/ami-launch-index) generates the peer's wireguard config.

The idea is - you can bake `all_peers_wg0.sh` into a (PRIVATE!) AMI (perhaps created via Packer), copy wg0.conf onto your server, then bake `setup-wg.service` into your AMI at `/etc/systemd/system/setup-wg.service` and run `systemctl enable setup-wg` on your AMI.

# Terraform

## IAM Policy Required

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "TerraformASGPolicy0",
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:DeleteSubnet",
                "ec2:CreateVpc",
                "ec2:AttachInternetGateway",
                "autoscaling:*",
                "ec2:DescribeVpcAttribute",
                "ec2:DeleteRouteTable",
                "ec2:ModifySubnetAttribute",
                "ec2:AssociateRouteTable",
                "ec2:DescribeInternetGateways",
                "ec2:GetLaunchTemplateData",
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateRoute",
                "ec2:CreateInternetGateway",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:DescribeAccountAttributes",
                "ec2:DeleteInternetGateway",
                "ec2:DeleteLaunchTemplateVersions",
                "ec2:DescribeKeyPairs",
                "ec2:DescribeNetworkAcls",
                "ec2:DescribeRouteTables",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:DeleteLaunchTemplate",
                "ec2:ImportKeyPair",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeVpcClassicLinkDnsSupport",
                "ec2:CreateTags",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:CreateRouteTable",
                "ec2:DetachInternetGateway",
                "ec2:DisassociateRouteTable",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeVpcClassicLink",
                "ec2:CreateLaunchTemplateVersion",
                "ec2:CreateLaunchTemplate",
                "iam:CreateServiceLinkedRole",
                "ec2:DescribeVpcs",
                "ec2:DeleteSecurityGroup",
                "ec2:ModifyLaunchTemplate",
                "ec2:DeleteVpc",
                "sts:GetCallerIdentity",
                "ec2:CreateSubnet",
                "ec2:DescribeSubnets",
                "ec2:DeleteKeyPair"
            ],
            "Resource": "*"
        }
    ]
}