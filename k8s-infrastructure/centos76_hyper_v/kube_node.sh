#! /bin/bash
PATH_TO_LAN=/etc/sysconfig/network-scripts/ifcfg-eth0
FILE_PATH="/etc/fstab"

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

# kubernetets services provision
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable --now kubelet

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

systemctl daemon-reload
systemctl restart kubelet

yum update -y

if grep -q '^/swapfile' ${FILE_PATH}
then
  sed -i 's/\/swapfile/#&/' ${FILE_PATH}

fi

swapoff -a

