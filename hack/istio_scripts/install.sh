#!/bin/bash
GREEN_COL="\\033[32;1m"         # green color
RED_COL="\\033[1;31m"           # red color
NORMAL_COL="\\033[0;39m"
IMAGE_TAR_SUFFIX=".tar.gz"

KUBECONFIG_PATH="../../.kubectl.kubeconfig"
CARGO_ENV_PATH="../../.install-env.sh"

if [ -f ${CARGO_ENV_PATH} ];then
source ${CARGO_ENV_PATH}
else
echo -e "$RED_COL Cargo env file not exist $NORMAL_COL"
exit 1
fi

if [ -f ${KUBECONFIG_PATH} ];then
echo -e "$GREEN_COL start installation $NORMAL_COL"
else
echo -e "$RED_COL kubeconfig file not exist $NORMAL_COL"
exit 1
fi

INSTALL_ROOT=$(cd $(dirname "${BASH_SOURCE}")/ && pwd -P)
CARGO_ROOT=$(cd ${INSTALL_ROOT} && pwd -P )
RELEASE_REGISTRY="harbor.caicloud.xyz"
IMGAE_REGEX="*.tar.gz$"
CARGO_PROJECT="release"

function load_all_images() {
    IMAGE_TARS=$(ls "${INSTALL_ROOT}/images/"| grep "${IMAGE_TAR_SUFFIX}" | xargs )

    echo -e "$GREEN_COL loading image, please wait...... $NORMAL_COL"

    for IMAGE_TAR in ${IMAGE_TARS[@]}
    do
        OLD_IMAGE=`docker load -i "${INSTALL_ROOT}/images/$IMAGE_TAR" | grep "Loaded image:" | sed 's/Loaded image: //g'`
        NEW_IMAGE=$(echo ${OLD_IMAGE} | sed "s/${RELEASE_REGISTRY}/${CARGO_CFG_DOMAIN}/g")
        docker tag ${OLD_IMAGE} ${NEW_IMAGE}
        docker push ${NEW_IMAGE}
    done
}

function install_istio() {
    echo -e "$GREEN_COL installing istio, please wait...... $NORMAL_COL"
    RELEASE_IMGAE_ROOT="${INSTALL_ROOT}/../image/"
    IMAGE_TARS=$(ls "${RELEASE_IMGAE_ROOT}" | grep "${IMAGE_TAR_SUFFIX}" | xargs )

    for IMAGE_TAR in ${IMAGE_TARS[@]}
    do
        RELEASE_IMAGE=`docker load -i "${RELEASE_IMGAE_ROOT}/$IMAGE_TAR" | grep "Loaded image:" | sed 's/Loaded image: //g'`
    done

    docker run --rm -it \
      -v `pwd`/${KUBECONFIG_PATH}:/root/.kube/config \
      -v `pwd`/crds.yaml:/pangolin/crds.yaml \
      -v `pwd`/istio.yaml:/pangolin/istio.yaml \
      ${RELEASE_IMAGE} \
      sh -c "kubectl apply -f crds.yaml && sleep 10 && kubectl apply -f istio.yaml"
}

function install_plugin() {
    echo -e "$GREEN_COL installing istio plugins, please wait...... $NORMAL_COL"
    PLUGINS=$(ls "${INSTALL_ROOT}/plugins/" | grep ".yaml" | xargs )
    for PLUGIN in ${PLUGINS[@]}
    do
        sed -i "s/${CARGO_CFG_DOMAIN}/${RELEASE_REGISTRY}/g" "${INSTALL_ROOT}/plugins/${PLUGINS}"
        `pwd`/../cadm plugin create -f ${INSTALL_ROOT}/plugins/${PLUGINS} --kubeconfig=`pwd`/${KUBECONFIG_PATH} -u admin -p Pwd123456
    done
}

# load image resource
load_all_images

# install istio
install_istio

# install istio plugin
install_plugin