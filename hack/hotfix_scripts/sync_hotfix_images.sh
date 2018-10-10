#!/bin/bash
#
# The script sync hotfix images from cargo.caicloudprivatetest.com to harbor.caicloud.xyz
# and save images to tar.gz file according to specific HOTFIXVERSION name
# see usage function for how to run.
#
# script/
# └── hotfix_scripts
#     └── sync_hotfix_images.sh

set -o nounset
set -o errexit

function usage {
  echo -e "Usage:"
  echo -e " bash sync_hotfix_images.sh [COMPASS-VERSION]"
  echo -e ""
  echo -e " The script sync hotfix images from cargo.caicloudprivatetest.com to harbor.caicloud.xyz"
  echo -e " and save images to tar.gz file according to specific HOTFIXVERSION name."
  echo -e ""
  echo -e "Parameter:"
  echo -e " COMPASS-VERSION\tcompass-version needed for image tar.gz files which saved from docker."
  echo -e ""
  echo -e "Example:"
  echo -e " bash sync_hotfix_images.sh v2.7.0"
}
# -----------------------------------------------------------------------------
# Parameters for syncing docker and saving images, see usage.
# -----------------------------------------------------------------------------
#
IMAGE_LIST_FILE="hotfixes.txt"
SOURCE_REGISTRY="cargo.caicloudprivatetest.com"
SOURCE_PROJECT="caicloud"
TARGET_REGISTRY="harbor.caicloud.xyz"
TARGET_PROJECT="release"
VERSION=$1

# print the usage.
if [[ "$#" == "1" ]]; then
  if [[ "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
    usage
    exit 0
  fi
fi

echo ${IMAGE_LIST_FILE} ${SOURCE_REGISTRY} ${SOURCE_PROJECT} ${TARGET_REGISTRY} ${TARGET_PROJECT}

for line in `cat ${IMAGE_LIST_FILE}`
do
    # pull images from cargo.caicloudprivatetest.com(192.168.8.254)
    docker pull ${SOURCE_REGISTRY}/${SOURCE_PROJECT}/$line
    if [[ $? != 0 ]]; then
        echo "Pull image ${SOURCE_PROJECT}/$line error, please login first"
        echo "${SOURCE_PROJECT}/$line" >> hotfix_miss_image.list
    fi

    docker tag ${SOURCE_REGISTRY}/${SOURCE_PROJECT}/$line ${TARGET_REGISTRY}/${TARGET_PROJECT}/$line
    echo "NEW IMAGE:${TARGET_REGISTRY}/${TARGET_PROJECT}/$line"

    # save docker image to tar.gz file
    IMAGE_NAME=`echo $line | cut -d \: -f 1`
    IMAGE_TAG=`echo $line | cut -d \: -f 2`
    FILE_NAME=$IMAGE_NAME"-"$VERSION"-"`date +%Y%m%d`"-"$IMAGE_TAG"-image.tar.gz"
    echo "save image: ${FILE_NAME}"
    docker save ${TARGET_REGISTRY}/${TARGET_PROJECT}/$line -o ${FILE_NAME}

    # push image to harbor.caicloud.xyz
    docker push ${TARGET_REGISTRY}/${TARGET_PROJECT}/$line
    if [[ $? != 0 ]]; then
        echo "Push image ${TARGET_PROJECT}/$line error, please login first"
        echo "${TARGET_PROJECT}/$line" >> hotfix_miss_push_image.list
    fi
done
