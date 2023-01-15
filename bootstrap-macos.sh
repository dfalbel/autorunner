mkdir actions-runner && cd actions-runner
curl -o actions-runner-osx-arm64-2.300.2.tar.gz -L https://github.com/actions/runner/releases/download/v2.300.2/actions-runner-osx-arm64-2.300.2.tar.gz
echo "c52f30610674acd0ea7c2d05e65c04c1dedf1606c2f00ce347640a001bafc568  actions-runner-osx-arm64-2.300.2.tar.gz" | shasum -a 256 -c
tar xzf ./actions-runner-osx-arm64-2.300.2.tar.gz
./config.sh --url https://github.com/{org} --token {runner_token} --ephemeral --labels {labels} --unattended
./svc.sh install
./svc.sh start
