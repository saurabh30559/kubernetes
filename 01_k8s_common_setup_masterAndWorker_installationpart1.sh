#!/bin/bash

# Prerequisites: MASTER: 2CPU, 4 Mem & SLAVES: 1 cpu, 1 mem ; ports -> allow all for your vpc - 172.31.0.0/16   
# COMMON FOR MASTER & SLAVES START


set -e  # Exit immediately if a command exits with a non-zero status

echo "Ensure the script is run as root"
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Try using: sudo $0"
   exit 1
fi

echo "Disabling swap and updating fstab to prevent re-enabling"
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "Installing containerd runtime dependencies"
apt-get update -y
sleep 15
apt-get install -y ca-certificates curl gnupg lsb-release
sleep 10

echo "Adding Docker's official GPG key"
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "Setting up Docker's repository for containerd"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Installing containerd runtime"
apt-get update -y
sleep 15
apt-get install -y containerd.io
sleep 15

echo "Generating default containerd configuration"
containerd config default > /etc/containerd/config.toml

echo "Configuring containerd to use systemd as cgroup driver"
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

echo "Restarting and enabling containerd service"
systemctl restart containerd
systemctl enable containerd

echo "Applying kernel settings required for Kubernetes networking"
cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

sysctl --system

echo "Installing Kubernetes components (kubelet, kubeadm, kubectl)"
apt-get update -y
sleep 10
apt-get install -y apt-transport-https ca-certificates curl gpg
sleep 10

echo "Adding Kubernetes signing key and repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "Adding Kubernetes apt repository"
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' > /etc/apt/sources.list.d/kubernetes.list

echo "Installing kubelet, kubeadm, and kubectl"
apt-get update -y
sleep 10
apt-get install -y kubelet kubeadm kubectl
sleep 10

echo "Holding Kubernetes packages to prevent automatic upgrade"
apt-mark hold kubelet kubeadm kubectl

echo "Enabling and starting kubelet service"
systemctl daemon-reexec
systemctl start kubelet
systemctl enable kubelet

echo "========== COMMON FOR MASTER & SLAVES SETUP COMPLETE =========="

