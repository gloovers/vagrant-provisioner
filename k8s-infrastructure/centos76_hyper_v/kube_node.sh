#! /bin/bash
PATH_TO_LAN=/etc/sysconfig/network-scripts/ifcfg-eth0
if grep 'BOOTPROTO' $PATH_TO_LAN | grep 'dhcp' -q
then
    sudo cat << EOF >$PATH_TO_LAN
TYPE="Ethernet"
BOOTPROTO="static"
ONBOOT="yes"
IPADDR=${1}
NETMASK=255.255.255.0
GATEWAY=172.16.0.1
DNS1=8.8.8.8
EOF
    sudo systemctl restart network
fi

yum install -y yum-utils jq net-tools git vim
yum-config-manager --add-repo \
      https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --enable docker-ce-edge
    
yum install -y docker-ce
systemctl enable docker
systemctl start docker
usermod -aG docker vagrant