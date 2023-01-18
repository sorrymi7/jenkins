systemctl restart sshd
kubectl get pod -o wide --watch
sudo swapoff /swap.img
sudo sed -i -e '/swap.img/d' /etc/fstab
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
systemctl restart docker
systemctl enable docker
git clone https://github.com/Mirantis/cri-dockerd.git
wget https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux
source ~/.bash_profile
cd cri-dockerd
mkdir bin
go build -o bin/cri-dockerd
mkdir -p /usr/local/bin
install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
cp -a packaging/systemd/* /etc/systemd/system
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
systemctl daemon-reload
systemctl enable cri-docker.service
systemctl enable --now cri-docker.socket
sudo systemctl restart docker && sudo systemctl restart cri-docker
sudo systemctl status cri-docker.socket --no-pager
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
"max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl restart docker && sudo systemctl restart cri-docker
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
kubectl version --short
sudo apt-mark hold kubelet kubeadm kubectl
sudo kubeadm config images pull --cri-socket unix:///run/cri-dockerd.sock
sudo kubeadm init --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address=211.183.3.100 --cri-socket /var/run/cri-dockerd.sock
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get node
curl https://projectcalico.docs.tigera.io/manifests/calico.yaml -O
sed -i -e 's?192.168.0.0/16?10.10.0.0/16?g' calico.yaml
kubectl apply -f calico.yaml
kubectl get node
kubectl create secret docker-registry docker-registry-login --docker-server=192.168.0.230:5000 --docker-username=test --docker-password=test --docker-email=test@test.com
kubectl get pod
kubectl get pod --all-namespaces
kubectl run test --image=nginx
10.10.235.129
curl 10.10.235.129
vi test.yml
kubectl delete pod test
kubectl apply -f test.yml
