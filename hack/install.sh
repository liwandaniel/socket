#!/bin/bash
set -o nounset
set -o errexit

# source the copy of config.sample
source config

source ../.install-env.sh

#create directory
PANGOLIN_ROOT=$(cd $(dirname "${BASH_SOURCE}")/ && pwd -P)
CARGO_ROOT=$(cd ${CARGO_CFG_PATH} && pwd -P )
COMMON_ROOT=$(cd ../common && pwd -P )

# Untar cargo resource
cd $CARGO_ROOT && bash $CARGO_ROOT/stop.sh
cd $PANGOLIN_ROOT && tar -xvf "$PANGOLIN_ROOT/pangolin-deploy-images.tar.gz" -C "$COMMON_ROOT/cargo-registry"

# To avoid Error: device or resource busy
systemctl restart docker

cd $CARGO_ROOT && bash $CARGO_ROOT/restart.sh
cd $PANGOLIN_ROOT

registry=$1
version=$2

if [ $PLATFORM_TYPE = "MINI" ] ; then
    deploy_yaml='mini-compass.yaml'
else
    deploy_yaml='compass.yaml'
fi

docker rm -f pangolin-deploy >/dev/null 2>&1 || true

docker run --name pangolin-deploy -it \
  -e DEPLOY_YAML=${deploy_yaml} \
  -v `pwd`/../.kubectl.kubeconfig:/root/.kube/config \
  -v `pwd`/config:/pangolin/config \
  ${registry}/release/pangolin:${version} \
  sh -c 'python3 amctl.py create -p /pangolin/${DEPLOY_YAML}'

