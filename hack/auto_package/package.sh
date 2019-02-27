#!/bin/bash
INPUT=$1
INPUT=${INPUT:=auto}

RELEASE_VERSION=$2
RELEASE_VERSION=${RELEASE_VERSION:=auto}

CARGO_DIR=$3
CARGO_DIR=${CARGO_DIR:="/compass"}

PRODUCT_NAME=$4
PRODUCT_NAME=${PRODUCT_NAME:="compass"}

GREEN_COL="\\033[32;1m"         # green color
RED_COL="\\033[1;31m"           # red color
NORMAL_COL="\\033[0;39m"

OSS_DIR="oss://infra-release/platform"

SOURCE_REGISTRY=source_registry
TARGET_REGISTRY=target_registry
RELEASE_REGISTRY=release_registry

case $INPUT in
  # sync images
  sync )
    echo -e "$GREEN_COL starting sync images $NORMAL_COL"
    SYNC_DIR=$5
    SYNC_DIR=${SYNC_DIR:="/root/sync-scripts"}
    rm -rf ${CARGO_DIR}/common/cargo-registry/docker
    bash ${CARGO_DIR}/cargo-ansible/cargo/restart.sh
    rm -rf ${SYNC_DIR}/images-lists/miss*
    bash ${SYNC_DIR}/sync.sh ${SOURCE_REGISTRY} ${TARGET_REGISTRY} ${SYNC_DIR}/images-lists
    bash ${SYNC_DIR}/sync.sh ${TARGET_REGISTRY} ${RELEASE_REGISTRY} ${SYNC_DIR}/images-lists
    ;;
  # check missed imgaes, if image missed, exit
  judge )
    SYNC_DIR=$5
    SYNC_DIR=${SYNC_DIR:="/root/sync-scripts"}
    if [ ! -f ${SYNC_DIR}/images-lists/miss_image.txt ];then
    echo -e "$GREEN_COL no missed image, will proceed $NORMAL_COL"
    else
    echo -e "$RED_COL got missed images, exit $NORMAL_COL"
    exit 1
    fi
    ;;
  # package the files
  package )
    echo -e "$GREEN_COL starting packaging $NORMAL_COL"
    PACKAGE_PATH=$5
    PACKAGE_PATH=${PACKAGE_PATH:="/platform"}
    mkdir -p ${PACKAGE_PATH}
    cd ${CARGO_DIR}/common/cargo-registry/ && tar -cvf pangolin-deploy-images.tar.gz docker
    cd ${PACKAGE_PATH} && mkdir  -p ${PRODUCT_NAME}-component-${RELEASE_VERSION}/image
    mv ${CARGO_DIR}/common/cargo-registry/pangolin-deploy-images.tar.gz ${PACKAGE_PATH}/${PRODUCT_NAME}-component-${RELEASE_VERSION}/
    ;;
  # upload the package
  upload )
    echo -e "$GREEN_COL starting uploading $NORMAL_COL"
    OSS_PATH=$5
    OSS_PATH=${OSS_PATH:=auto}
    # delete the "/" at the begin and end of path
    OSS_PATH=`echo ${OSS_PATH%*/}` | sed 's#^/##g'
    PACKAGE_PATH=$6
    PACKAGE_PATH=${PACKAGE_PATH:="/platform"}
    PACKAGE_PATH=`echo ${PACKAGE_PATH%*/}`
    cd ${PACKAGE_PATH} && tar cvf ${PRODUCT_NAME}-component-${RELEASE_VERSION}.tar.gz ${PRODUCT_NAME}-component-${RELEASE_VERSION}
    echo -e "$GREEN_COL will upload to ${OSS_DIR}/${OSS_PATH}/${PRODUCT_NAME}-component-${RELEASE_VERSION}.tar.gz $NORMAL_COL"
    /root/ossutil cp -ru ${PACKAGE_PATH}/${PRODUCT_NAME}-component-${RELEASE_VERSION}.tar.gz ${OSS_DIR}/${OSS_PATH}/${PRODUCT_NAME}-component-${RELEASE_VERSION}.tar.gz
    ;;
  * )
    echo -e "$RED_COL unknown command param:${INPUT} $NORMAL_COL"
    exit 1
    ;;
esac
