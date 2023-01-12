#! /bin/bash

adduser --disabled-password --gecos "" actions
cd /home/actions

if [ {gpu} ]
then
  sudo cos-extensions install gpu
fi

sudo -u actions mkdir actions-runner && cd actions-runner
sudo -u actions curl -o actions-runner-linux-x64-2.300.2.tar.gz -L https://github.com/actions/runner/releases/download/v2.300.2/actions-runner-linux-x64-2.300.2.tar.gz
sudo -u actions echo "ed5bf2799c1ef7b2dd607df66e6b676dff8c44fb359c6fedc9ebf7db53339f0c  actions-runner-linux-x64-2.300.2.tar.gz" | shasum -a 256 -c
sudo -u actions tar xzf ./actions-runner-linux-x64-2.300.2.tar.gz
sudo -u actions ./config.sh --url https://github.com/{org} --token {runner_token} --ephemeral --labels {labels} --unattended
./svc.sh install
./svc.sh start
