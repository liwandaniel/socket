#!/bin/bash
input=$1
input=${input:=install}

GREEN_COL="\\033[32;1m"         # green color
RED_COL="\\033[1;31m"           # red color
NORMAL_COL="\\033[0;39m"
IMAGE_TAR_SUFFIX=".tar.gz"

# source the copy of config.sample
if [ -f ./config ];then
source config
else
echo -e "$RED_COL config file not exist $NORMAL_COL"
exit 1
fi

if [ -f ../.install-env.sh ];then
source ../.install-env.sh
else
echo -e "$RED_COL Cargo env file not exist $NORMAL_COL"
exit 1
fi

if [ -f ../.kubectl.kubeconfig ];then
echo -e "$GREEN_COL let's play $NORMAL_COL"
else
echo -e "$RED_COL kubeconfig file not exist $NORMAL_COL"
exit 1
fi

PANGOLIN_ROOT=$(cd $(dirname "${BASH_SOURCE}")/ && pwd -P)
CARGO_ROOT=$(cd ${CARGO_CFG_PATH} && pwd -P )
COMMON_ROOT=$(cd ../common && pwd -P )
PANGOLIN_HOTFIX=$PANGOLIN_ROOT/hotfixes
RELEASE_REGISTRY="harbor.caicloud.xyz"
HOTFIX_REGEX=".*hotfixes.*.tar.gz$"
CARGO_PROJECT="release"

# Load image
IMAGE_TARS=$(ls "$PANGOLIN_ROOT/image/"| grep "${IMAGE_TAR_SUFFIX}" | xargs )

echo -e "$GREEN_COL loading image, please wait...... $NORMAL_COL"

for IMAGE_TAR in ${IMAGE_TARS[@]}
do
    RELEASE_IMAGE=`docker load -i "$PANGOLIN_ROOT/image/$IMAGE_TAR" | grep "Loaded image:" | sed 's/Loaded image: //g'`
    docker tag ${RELEASE_IMAGE} "${CARGO_CFG_DOMAIN}/${CARGO_PROJECT}/${RELEASE_IMAGE}"
    docker push "${CARGO_CFG_DOMAIN}/${CARGO_PROJECT}/${RELEASE_IMAGE}" > /dev/null
done

function load_all_images() {
    # Untar cargo resource
    cd $PANGOLIN_ROOT && tar -xvf "$PANGOLIN_ROOT/pangolin-deploy-images.tar.gz" -C "$COMMON_ROOT/cargo-registry"
    docker restart harbor-ui
    cd $PANGOLIN_ROOT
}

handle_hotfix() {
    HOTFIX_TARS=$(ls | grep  "${HOTFIX_REGEX}" | xargs )
    for HOTFIX_TAR in ${HOTFIX_TARS[@]}
    do
        HOTFIX=$(echo ${HOTFIX_TAR} | sed 's/.tar.gz//g')
        tar xf $HOTFIX_TAR
        cd ${HOTFIX}
        echo -e "$GREEN_COL Handling hotfix: ${HOTFIX} $NORMAL_COL "

        IMAGE_TARS=$(ls | grep "${IMAGE_TAR_SUFFIX}" | xargs )

        for IMAGE_TAR in ${IMAGE_TARS[@]}
        do
            OLD_IMAGE=$(docker load -i $IMAGE_TAR | grep 'Loaded image: ' | sed 's/Loaded image://g')
            NEW_IMAGE=$(echo ${OLD_IMAGE} | sed "s/${RELEASE_REGISTRY}/${CARGO_CFG_DOMAIN}/g")
            docker tag ${OLD_IMAGE} ${NEW_IMAGE}
            docker push ${NEW_IMAGE}
        done
        cd -
    done
}

if [ ! -d "./image" ] ; then
echo -e "$RED_COL release image not exist $NORMAL_COL"
exit 1
fi

case $input in
  # install standard components
  install )
    echo -e "$GREEN_COL installing component $NORMAL_COL"
    if [ ! -n "$COMPONENT_LIST" ] ; then
        deploy_yaml='compass.yaml'
    else
        deploy_yaml=$COMPONENT_LIST
    fi

    if [ ! -n "$ADDONS_PATH" ] ; then
        addons="addons"
    else
        addons=$ADDONS_PATH
    fi

    echo -e "$GREEN_COL installing components from ${addons} by using ${deploy_yaml} $NORMAL_COL"

    # load image resource
    load_all_images

    docker run --rm -it \
      -e DEPLOY_YAML=${deploy_yaml} \
      -v `pwd`/../.kubectl.kubeconfig:/root/.kube/config \
      -v `pwd`/config:/pangolin/config \
      ${RELEASE_IMAGE} \
      sh -c 'python3 amctl.py create -p /pangolin/${DEPLOY_YAML}'
    ;;
  # install hotfixes
  hotfix )
    echo -e "$GREEN_COL installing hotfixes $NORMAL_COL"
    if [ ! -d "./hotfixes" ] ; then
    echo -e "$RED_COL hotfixes not exist $NORMAL_COL"
    exit 1
    fi

    cd $PANGOLIN_HOTFIX
    handle_hotfix
    cd $PANGOLIN_ROOT

    docker run --rm -it \
      -v `pwd`/hotfixes:/pangolin/hotfixes \
      -v `pwd`/../.kubectl.kubeconfig:/root/.kube/config \
      -v `pwd`/config:/pangolin/config \
      ${RELEASE_IMAGE} \
      sh -c 'python3 amctl.py update -p hotfixes/'
    ;;
  # debug mode
  debug )
    echo -e "$GREEN_COL running debug mode $NORMAL_COL"
    docker run --rm -it \
      -v `pwd`/../.kubectl.kubeconfig:/root/.kube/config \
      -v `pwd`/config:/pangolin/config \
      ${RELEASE_IMAGE} bash
    ;;
  * )
    echo -e "$RED_COL unknown command $NORMAL_COL"
    exit 1
    ;;
esac