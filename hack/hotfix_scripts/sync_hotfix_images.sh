#!/bin/bash
#
# The script sync hotfix images from cargo.caicloudprivatetest.com to harbor.caicloud.xyz
# and save images to tar.gz file according to specific HOTFIXVERSION name
# see usage function for how to run.
#
# hack/
# └── hotfix_scripts
#     └── sync_hotfix_images.sh

function usage {
  echo -e "Usage:"
  echo -e " bash sync_hotfix_images.sh [HOTFIX_YAML_PATH] [UPLOAD_OSS_PATH]"
  echo -e ""
  echo -e " The script sync hotfix images from cargo-infra.caicloud.xyz to harbor.caicloud.xyz"
  echo -e " and save images to tar.gz file, then upload packages to certain path of oss server"
  echo -e ""
  echo -e "Parameter:"
  echo -e " HOTFIX_YAML_PATH\tthe path of hotfix yaml"
  echo -e " UPLOAD_OSS_PATH\tthe path to upload hotfix packages"
  echo -e ""
  echo -e "Example:"
  echo -e " bash sync_hotfix_images.sh /path/of/product-release/release-hotfixes/2.7.1/20180905 compass-v2.7.2/"
  echo -e " will upload to oss://infra-release/platform/compass-v2.7.2/hotfixes/20180905/..."
}
# -----------------------------------------------------------------------------
# Parameters for syncing docker and saving images, see usage.
# -----------------------------------------------------------------------------
#

HOTFIX_YAML_PATH=$1
UPLOAD_OSS_PATH=$2
HOTFIX_LISTS_SUFFIX="compass-hotfixes"
SOURCE_REGISTRY="cargo-infra.caicloud.xyz"
SOURCE_PROJECT="devops_release"
TARGET_REGISTRY="harbor.caicloud.xyz"
TARGET_PROJECT="release"
TARGET_PATH="./hotfixes"

# get compass version by parsing the path
COMPASS_VERSION=`echo $HOTFIX_YAML_PATH |grep -o -e "release-hotfixes/.*/" | awk -F '/' '{print$2}'`

GREEN_COL="\\033[32;1m"         # green color
RED_COL="\\033[1;31m"           # red color
NORMAL_COL="\\033[0;39m"

# print the usage.
if [[ "$#" == "1" ]]; then
  if [[ "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
    usage
    exit 0
  fi
fi

function saveImages(){
    # if the path end with .yaml, start parsing the yaml and saving image
    if [ "${1##*.}" = "yaml" ]; then
    echo -e "$GREEN_COL ########## handling ${1} ##########$NORMAL_COL"
    images=$( cat "${1}" | grep -e "image:.*" | grep -o "/.*" | sed $'s/\'//g' | sed $'s/\///g')
    for image in ${images[@]}
    do
        FULL_IMAGE="${SOURCE_REGISTRY}/${SOURCE_PROJECT}/${image}"
        # pull images
        docker pull ${FULL_IMAGE}
        if [[ $? != 0 ]]; then
            echo -e "$RED_COL Pull image ${FULL_IMAGE} error... $NORMAL_COL"
            echo ${FULL_IMAGE} >> miss_image.txt
        else
            echo -e "$GREEN_COL image ${FULL_IMAGE} successfully pulled $NORMAL_COL"
            NEW_IMAGE="${TARGET_REGISTRY}/${TARGET_PROJECT}/${image}"
            echo ${NEW_IMAGE}
            docker tag ${FULL_IMAGE} ${NEW_IMAGE}
            docker push ${NEW_IMAGE}
            if [[ $? != 0 ]]; then
                echo -e "$RED_COL Push image ${NEW_IMAGE} error... $NORMAL_COL"
                echo "${NEW_IMAGE}" >> miss_push_image.txt
            else
                # save images and yaml
                echo -e "$GREEN_COL ${NEW_IMAGE} successfully pushed $NORMAL_COL"
                IMAGE_NAME=`echo $image | cut -d \: -f 1`
                IMAGE_TAG=`echo $image | cut -d \: -f 2`
                IMAGE_SUFFIX="-image.tar.gz"
                FULL_NAME="compass-hotfixes-"$COMPASS_VERSION"-"`date +%Y%m%d`"-"$IMAGE_NAME"-"$IMAGE_TAG
                IMAGE_NAME="${FULL_NAME}${IMAGE_SUFFIX}"
                echo -e "$GREEN_COL saving image to file ${IMAGE_NAME}...... $NORMAL_COL"
                # make new dir in TARGET_PATH to save image and yaml
                mkdir "${TARGET_PATH}/${FULL_NAME}"
                docker save ${NEW_IMAGE} -o "${TARGET_PATH}/${FULL_NAME}/${IMAGE_NAME}"
                cp "${1}" "${TARGET_PATH}/${FULL_NAME}"
                cd ${TARGET_PATH} && tar cvf "${FULL_NAME}.tar.gz" "${FULL_NAME}" && rm -rf ${FULL_NAME}
                cd -
            fi
        fi
    done
    elif [ -d $1 ]
    then
        for element in `ls $1`
        do
            dir_or_file=$1"/"$element
            # go on with function until got yaml
            saveImages $dir_or_file
        done
    # if the file end with .md, then cp this file
    elif [ "${1##*.}" = "md" ]; then
        cp "${1}" "${TARGET_PATH}"
    fi
}

function upload(){
    for file in `ls ${TARGET_PATH}`
    do
    FULL_UPLOAD_PATH="oss://infra-release/platform/${UPLOAD_OSS_PATH}/hotfixes/`date +%Y%m%d`/${file}"
    echo -e "$GREEN_COL uploading ${file} to ${FULL_UPLOAD_PATH}...... $NORMAL_COL"
    # upload to oss, need to set configuration on "~" path
    ~/ossutil-mac cp -ru "${TARGET_PATH}/${file}" ${FULL_UPLOAD_PATH}
    done
}

rm -rf $TARGET_PATH
mkdir $TARGET_PATH

# delete the "/" end of path
HOTFIX_YAML_PATH=`echo ${HOTFIX_YAML_PATH%*/}`
UPLOAD_OSS_PATH=`echo ${UPLOAD_OSS_PATH%*/}`

saveImages "${HOTFIX_YAML_PATH}"

upload

