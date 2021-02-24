#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

set -x

sudo unlink /etc/firecracker-containerd/fccd-cri.sock
sudo ${SCRIPT_DIR}/clean_fcctr.sh

sudo containerd &
sleep 10
sudo PATH=${PATH} /usr/local/bin/firecracker-containerd --config /etc/firecracker-containerd/config.toml &
sleep 15

cd ${SCRIPT_DIR}/../
source /etc/profile && go clean && go build && sudo ./vhive --dbg |& tee ~/disagg-mem-sys/vhive.log

set +x
