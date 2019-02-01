#!/bin/bash

GREEN_COL="\\033[32;1m"         # green color
RED_COL="\\033[1;31m"           # red color
NORMAL_COL="\\033[0;39m"

function usage {
  echo -e "Usage:"
  echo -e " bash istio_package.sh [ISTIO_DIR] [PLUGIN_YAML_PATH] [PACKAGE_VERSION]"
  echo -e ""
  echo -e " The script make istio package include istio resources and plugins"
  echo -e ""
  echo -e "Parameter:"
  echo -e " ISTIO_DIR\t the dir path of istio.yaml, crds.yaml, install.sh"
  echo -e " PLUGIN_YAML_PATH\t the path of plugin yaml"
  echo -e " PACKAGE_VERSION\t the version of istio package"
  echo -e " SCRIPTS_PATH\t the path of install scripts"
  echo -e ""
  echo -e "Example:"
  echo -e "     bash istio_package.sh hack/istio_scripts/ release-plugins/istio-manager.yaml v1.0.0 "
}

ISTIO_DIR=$1
ISTIO_DIR=${ISTIO_DIR:="hack/istio_scripts/"}
ISTIO_DIR=`echo ${ISTIO_DIR%*/}`

# Try relative path
if [ -e "`pwd`/${ISTIO_DIR}" ];then
ISTIO_DIR="`pwd`/${ISTIO_DIR}"
# Try absolute path
elif [ -e "${ISTIO_DIR}" ];then
ISTIO_DIR="${ISTIO_DIR}"
# Exit if path not found
else
echo -e "$RED_COL istio path not exists $NORMAL_COL"
exit 1
fi

PLUGIN_FILE_PATH=$2
PLUGIN_FILE_PATH=${PLUGIN_FILE_PATH:="release-plugins/istio-manager.yaml"}

ISTIO_VERSION=$3
ISTIO_VERSION=${ISTIO_VERSION:="v1.0.0"}

GREEN_COL="\\033[32;1m"         # green color
RED_COL="\\033[1;31m"           # red color
NORMAL_COL="\\033[0;39m"

SOURCE_REGISTRY="cargo-infra.caicloud.xyz"
SOURCE_PROJECT="devops_release"
TARGET_REGISTRY="harbor.caicloud.xyz"
PACKAGE_PREFIX="compass-plugins-istio-${ISTIO_VERSION}"

# print the usage.
if [[ "$#" == "1" ]]; then
  if [[ "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
    usage
    exit 0
  fi
fi

mkdir -p "${PACKAGE_PREFIX}/images"
mkdir -p "${PACKAGE_PREFIX}/plugins"
cp ${ISTIO_DIR}/*.yaml "${PACKAGE_PREFIX}/"
cp ${ISTIO_DIR}/*.sh "${PACKAGE_PREFIX}/"
cp "${PLUGIN_FILE_PATH}" "${PACKAGE_PREFIX}/plugins"

function save_image(){
    image_lists=`(cat image.list)`
    for image_str in ${image_lists}
    do
        TARGET_PROJECT=`echo ${image_str} | awk -F "/" '{print $2}'`
        image=`echo ${image_str} | awk -F "/" '{print $3}'`
        FULL_IMAGE="${SOURCE_REGISTRY}/${SOURCE_PROJECT}/${image}"
        # pull images
        echo -e "$GREEN_COL pulling image ${FULL_IMAGE} $NORMAL_COL"
        docker pull ${FULL_IMAGE}
        NEW_IMAGE="${TARGET_REGISTRY}/${TARGET_PROJECT}/${image}"
        echo ${NEW_IMAGE}
        docker tag ${FULL_IMAGE} ${NEW_IMAGE}
        docker push ${NEW_IMAGE}
        if [[ $? != 0 ]]; then
            echo -e "$RED_COL Push image ${NEW_IMAGE} error... $NORMAL_COL"
            echo "${NEW_IMAGE}" >> miss_push_image.txt
            exit 1
        else
            # save images
            echo -e "$GREEN_COL ${NEW_IMAGE} successfully pushed $NORMAL_COL"
            IMAGE_NAME=`echo $image | cut -d \: -f 1`
            IMAGE_TAG=`echo $image | cut -d \: -f 2`
            FULL_NAME="istio-"${IMAGE_NAME}-${IMAGE_TAG}"-image.tar.gz"
            echo -e "$GREEN_COL saving image to file ${FULL_NAME}...... $NORMAL_COL"
            docker save ${NEW_IMAGE} -o "${PACKAGE_PREFIX}/images/${FULL_NAME}"
        fi
    done
}

cat "${ISTIO_DIR}/istio.yaml" | grep -E -o "harbor.caicloud.xyz.*" | awk '{print$1}' | sed "s# ##g;s#'##g;s/\"//g" | sort | uniq > image.list
cat "${PLUGIN_FILE_PATH}" | grep "image:" | awk '{print$2}' | sed "s# ##g;s#'##g;s/\"//g" >> image.list

save_image