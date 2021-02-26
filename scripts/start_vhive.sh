#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

set -x

sudo unlink /etc/firecracker-containerd/fccd-cri.sock
sudo ${SCRIPT_DIR}/clean_fcctr.sh

cd ${SCRIPT_DIR}/../

rm vhive.log containerd.log fc-containerd.log

sudo containerd &> ./containerd.log &
sleep 10
sudo PATH=${PATH} /usr/local/bin/firecracker-containerd --config /etc/firecracker-containerd/config.toml &> ./fc-containerd.log &
sleep 15

source /etc/profile && go clean && go build && sudo ./vhive --hostIface ${HOST_INTERFACE} &> ./vhive.log

set +x
