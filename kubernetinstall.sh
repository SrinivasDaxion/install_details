#main document 
#https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

# #Combine both youtube vedios
#https://www.youtube.com/watch?v=z_w3me8tmJA
#https://www.youtube.com/watch?v=7k9Rdlx30OY

#Git hub code for the vedios
#https://www.itsgeekhead.com/tuts/kubernetes-126-ubuntu-2204.txt
#https://github.com/kunchalavikram1427/YouTube_Series/blob/main/Kubernetes/ClusterSetup/Kubernetes_on_aws_with_containerd.md

# AddOn To Networking and Network Policy.
https://kubernetes.io/docs/concepts/cluster-administration/addons/

#Verfiy MAC address should differ
sudo cat /sys/class/dmi/id/product_uuid

#====My Code File=====
KUBERNETES 1.26
CONTAINERD 1.6.16
UBUNTU 22.04

### ALL: 

sudo -s

#printf "\n192.168.15.93 k8s-control\n192.168.15.94 k8s-2\n\n" >> /etc/hosts
printf "\n192.168.2.6 ubuntmaster\n192.168.2.7 ubuntunode1\n192.168.2.8 ubuntunode2\n\n" >> /etc/hosts

#printf "overlay\nbr_netfilter\n" >> /etc/modules-load.d/containerd.conf
#modprobe overlay
#modprobe br_netfilter
#printf "net.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\n" >> /etc/sysctl.d/99-kubernetes-cri.conf
#sysctl --system

#===notes====https://github.com/containerd/containerd/blob/main/docs/getting-started.md

#wget https://github.com/containerd/containerd/releases/download/v1.6.16/containerd-1.6.16-linux-amd64.tar.gz -P /tmp/
wget https://github.com/containerd/containerd/releases/download/v1.7.2/containerd-1.7.2-linux-amd64.tar.gz -p /tmp/
tar Cxzvf /usr/local /tmp/containerd-1.6.16-linux-amd64.tar.gz

wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -P /etc/systemd/system/

systemctl daemon-reload
systemctl enable --now containerd

#wget https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.amd64 -P /tmp/
wget https://github.com/opencontainers/runc/releases/download/v1.1.7/runc.amd64 -p /tmp/

install -m 755 /tmp/runc.amd64 /usr/local/sbin/runc

#wget https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz -P /tmp/
wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz -P /tmp/
mkdir -p /opt/cni/bin
#tar Cxzvf /opt/cni/bin /tmp/cni-plugins-linux-amd64-v1.2.0.tgz
tar Cxzvf /opt/cni/bin /tmp/cni-plugins-linux-amd64-v1.3.0.tgz

#=====Adding line ======
VERSION="v1.27.0" # check latest version in /releases page
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz

cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: false
pull-image-on-create: false
EOF

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
modprobe br_netfilter
sysctl -p /etc/sysctl.conf

#============================

#mkdir -p /etc/containerd
#containerd config default | tee /etc/containerd/config.toml   <<<<<<<<<<< manually edit and change systemdCgroup to true
#systemctl restart containerd

#Disable SWAP
swapoff -a  <<<<<<<< just disable it in /etc/fstab instead

#check the below which one is work
apt-get update && apt-get install -y apt-transport-https ca-certificates curl
apt-get update && apt-get install -y apt-transport-https curl

#curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
#===use the blow link insted of goole link========
curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg  https://dl.k8s.io/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update

reboot

sudo -s

#apt-get install -y kubelet=1.26.1-00 kubeadm=1.26.1-00 kubectl=1.26.1-00
apt-get install -y kubelet=1.27.1-00 kubeadm=1.27.1-00 kubectl=1.27.1-00
apt-mark hold kubelet kubeadm kubectl

# check swap config, ensure swap is 0
free -m


### ONLY ON CONTROL NODE .. control plane install:
#kubeadm init --pod-network-cidr 10.10.0.0/16 --kubernetes-version 1.26.1 --node-name k8s-control
kubeadm init --pod-network-cidr 10.10.0.0/16 --kubernetes-version 1.27.1 --node-name ubuntmaster


# add Calico 3.25 CNI 
### https://docs.tigera.io/calico/3.25/getting-started/kubernetes/quickstart
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
wget https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml
vi custom-resources.yaml <<<<<< edit the CIDR for pods if its custom
kubectl apply -f custom-resources.yaml

# get worker node commands to run to join additional nodes into cluster
kubeadm token create --print-join-command



## ONLY ON WORKER nodes
Run the command from the token create output above
