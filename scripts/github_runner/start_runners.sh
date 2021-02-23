# MIT License
#
# Copyright (c) 2020 Dmitrii Ustiugov, Shyam Jesalpura and EASE lab
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#!/bin/bash

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] || [ -z $4 ]; then
    echo "Parameters missing"
    echo "USAGE: start_runners.sh <num of runners> https://github.com/<OWNER>/<REPO> <Github Access key> <runner label(comma separated)>"
    exit -1
fi

# fetch runner token using access token
ACCESS_TOKEN=$3
API_VERSION=v3
API_HEADER="Accept: application/vnd.github.${API_VERSION}+json"
AUTH_HEADER="Authorization: token ${ACCESS_TOKEN}"

_SHORT_URL=$2
REPO_NAME="$(echo "${_SHORT_URL}" | grep / | cut -d/ -f4-)"
_FULL_URL="https://api.github.com/repos/${REPO_NAME}/actions/runners/registration-token"

RUNNER_TOKEN="$(curl -XPOST -fsSL \
  -H "${AUTH_HEADER}" \
  -H "${API_HEADER}" \
  "${_FULL_URL}" \
| jq -r '.token')"

# pull latest images
docker pull vhiveease/integ_test_runner
docker pull vhiveease/cri_test_runner

for number in $(seq 1 $1)
do
    case "$4" in
    "integ")
        # create access token as mentioned here (https://github.com/myoung34/docker-github-actions-runner#create-github-personal-access-token)
        CONTAINERID=$(docker run -d --restart always --privileged \
            --name "integration_test-github_runner-${number}" \
            -e REPO_URL="${_SHORT_URL}" \
            -e ACCESS_TOKEN="${ACCESS_TOKEN}" \
            -e LABELS="${3}" \
            --ipc=host \
            -v /var/run/docker.sock:/var/run/docker.sock \
            --volume /dev:/dev \
            --volume /run/udev/control:/run/udev/control \
            vhiveease/integ_test_runner)
        ;;
    "cri")
        ~/kind/kind create cluster --image vhiveease/cri_test_runner --name "cri-test-github-runner-${number}"
        sleep 2m
        docker exec -it \
            -e RUNNER_ALLOW_RUNASROOT=1 \
            -w /root/actions-runner \
            "cri-test-github-runner-${number}-control-plane" \
            ./config.sh \
                --url "${_SHORT_URL}" \
                --token "${RUNNER_TOKEN}" \
                --name "cri-test-github-runner-${number}-control-plane" \
                --work "/root/_work" \
                --labels "cri" \
                --unattended \
                --replace
        sleep 20s
        docker exec -it \
            "cri-test-github-runner-${number}-control-plane" \
            systemctl daemon-reload
        docker exec -it \
            "cri-test-github-runner-${number}-control-plane" \
            systemctl enable connect_github_runner --now
        ;;
    *)
        echo "Invalid label"
        ;;
    esac

    
done
