#!/bin/bash

echo "[TASK 1] Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

#echo "[TASK 2] Stop and Disable firewall"
#systemctl disable --now ufw >/dev/null 2>&1

echo "[TASK 2] Enable and Load Kernel modules"
cat >>/etc/modules-load.d/containerd.conf<<EOF
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

echo "[TASK 3] Add Kernel settings"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system >/dev/null 2>&1

#echo "[TASK 5] Install containerd runtime"
echo "[TASK 4] Install Docker runtime"
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum update -y && sudo yum install -y containerd.io-1.2.13 docker-ce-19.03.11 docker-ce-cli-19.03.11
mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker
# If you want the docker service to start on boot, run the following command:
systemctl enable docker
