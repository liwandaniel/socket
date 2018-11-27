#!/bin/bash
input=$1
input=${input:=auto}

version=$2
version=${version:=auto}

cargo_dir=$3
cargo_dir=${cargo_dir:="/compass"}

sync_dir=$4
sync_dir=${sync_dir:="/root/sync-scripts"}

oss_path=$5
oss_path=${oss_path:=auto}

GREEN_COL="\\033[32;1m"         # green color
RED_COL="\\033[1;31m"           # red color
NORMAL_COL="\\033[0;39m"

ROOT_DIR=${cargo_dir}
SYNC_DIR=${sync_dir}
RELEASE_VERSION=${version}
OSS_DIR="oss://infra-release/platform"

SOURCE_REGISTRY=source_registry
TARGET_REGISTRY=target_registry
RELEASE_REGISTRY=release_registry

case $input in
  # sync images
  sync )
    echo -e "$GREEN_COL starting sync images $NORMAL_COL"
    rm -rf ${ROOT_DIR}/common/cargo-registry/docker
    bash ${ROOT_DIR}/cargo-ansible/cargo/restart.sh
    rm -rf ${SYNC_DIR}/images-lists/miss*
    bash ${SYNC_DIR}/sync.sh ${SOURCE_REGISTRY} ${TARGET_REGISTRY} ${SYNC_DIR}/images-lists
    bash ${SYNC_DIR}/sync.sh ${TARGET_REGISTRY} ${RELEASE_REGISTRY} ${SYNC_DIR}/images-lists
    ;;
  # check missed imgaes, if image missed, exit
  judge )
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
    cd ${ROOT_DIR}/common/cargo-registry/ && tar -cvf pangolin-deploy-images.tar.gz docker
    cd ${ROOT_DIR} && mkdir -p compass-component-${RELEASE_VERSION}/image
    mv ${ROOT_DIR}/common/cargo-registry/pangolin-deploy-images.tar.gz ${ROOT_DIR}/compass-component-${RELEASE_VERSION}/
    ;;
  # upload the package
  upload )
    echo -e "$GREEN_COL starting uploading $NORMAL_COL"
    OSS_PATH=$oss_path
    cd ${ROOT_DIR} && tar cvf compass-component-${RELEASE_VERSION}.tar.gz compass-component-${RELEASE_VERSION}
    echo -e "$GREEN_COL will upload to ${OSS_DIR}/${OSS_PATH}/compass-component-${RELEASE_VERSION}.tar.gz $NORMAL_COL"
    /root/ossutil cp -ru ${ROOT_DIR}/compass-component-${RELEASE_VERSION}.tar.gz ${OSS_DIR}/${OSS_PATH}/compass-component-${RELEASE_VERSION}.tar.gz
    ;;
  * )
    echo -e "$RED_COL unknown command param:${input} $NORMAL_COL"
    exit 1
    ;;
esac
