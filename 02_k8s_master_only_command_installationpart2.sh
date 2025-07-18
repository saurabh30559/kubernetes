#!/bin/bash

#=========== In Master Node Only Start ===============

set -e

echo "Ensure the script is run as root"
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Try: sudo $0"
   exit 1
fi

echo "Initializing Kubernetes Master node. This may take some time... Please wait and do nothing"
kubeadm init
sleep 20

# Assuming default user is ubuntu. You may modify this if using a different non-root user.
UBUNTU_USER="ubuntu"
USER_HOME="/home/$UBUNTU_USER"

echo "Setting up kubeconfig for user '$UBUNTU_USER'"
mkdir -p "$USER_HOME/.kube"
cp -i /etc/kubernetes/admin.conf "$USER_HOME/.kube/config"
chown $UBUNTU_USER:$UBUNTU_USER "$USER_HOME/.kube/config"

echo "Applying Calico CNI network plugin"
sudo -u $UBUNTU_USER kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo
echo "========== Kubernetes Master Node Initialization Complete =========="
echo
echo "To join worker nodes to this cluster, run the following command on this master node:"
echo
echo "  kubeadm token create --print-join-command"
echo
echo "Then, copy and run that command on each worker node *as root*."
echo
#=========== In Master Node Only End ===============

