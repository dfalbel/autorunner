#! /bin/bash

adduser --disabled-password --gecos "" actions
cd /home/actions

# set self-destructing after 1 hour
# this will turn off the instance, but won't delete its disk, etc.
# at least can avoid some costs.
sudo shutdown -h +120

# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

if [ "{gpu}" == "1" ]
then
  # GPU driver installation instructions from:
  # https://cloud.google.com/compute/docs/gpus/install-drivers-gpu
  curl https://autorunner-task-handler-fzwjxdcwoq-uc.a.run.app/driver/install_gpu_driver.py --output install_gpu_driver.py
  sudo python3 install_gpu_driver.py


  distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  sudo apt-get update
  sudo apt-get install -y nvidia-docker2
  sudo systemctl restart docker
fi

sudo -u actions mkdir actions-runner && cd actions-runner
sudo -u actions curl -o actions-runner-linux-x64-2.300.2.tar.gz -L https://github.com/actions/runner/releases/download/v2.300.2/actions-runner-linux-x64-2.300.2.tar.gz
sudo -u actions echo "ed5bf2799c1ef7b2dd607df66e6b676dff8c44fb359c6fedc9ebf7db53339f0c  actions-runner-linux-x64-2.300.2.tar.gz" | shasum -a 256 -c
sudo -u actions tar xzf ./actions-runner-linux-x64-2.300.2.tar.gz
sudo -u actions ./config.sh --url https://github.com/{org} --token {runner_token} --ephemeral --labels {labels} --unattended
./svc.sh install
./svc.sh start
