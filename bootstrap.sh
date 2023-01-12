#! /bin/bash

adduser --disabled-password --gecos "" actions
cd /home/actions

# install docker
function install_docker () {
  sudo apt-get update
  sudo apt-get install \
      ca-certificates \
      curl \
      gnupg \
      lsb-release
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

install_docker

if [ "{gpu}" == "1" ]
then
  # GPU driver installation instructions from:
  # https://cloud.google.com/compute/docs/gpus/install-drivers-gpu
  curl https://raw.githubusercontent.com/GoogleCloudPlatform/compute-gpu-installation/main/linux/install_gpu_driver.py --output install_gpu_driver.py
  sudo python3 install_gpu_driver.py
fi

sudo -u actions mkdir actions-runner && cd actions-runner
sudo -u actions curl -o actions-runner-linux-x64-2.300.2.tar.gz -L https://github.com/actions/runner/releases/download/v2.300.2/actions-runner-linux-x64-2.300.2.tar.gz
sudo -u actions echo "ed5bf2799c1ef7b2dd607df66e6b676dff8c44fb359c6fedc9ebf7db53339f0c  actions-runner-linux-x64-2.300.2.tar.gz" | shasum -a 256 -c
sudo -u actions tar xzf ./actions-runner-linux-x64-2.300.2.tar.gz
sudo -u actions ./config.sh --url https://github.com/{org} --token {runner_token} --ephemeral --labels {labels} --unattended
./svc.sh install
./svc.sh start
