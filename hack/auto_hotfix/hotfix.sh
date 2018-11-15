#!/bin/bash
#
# The script sync hotfix images from cargo.caicloudprivatetest.com to harbor.caicloud.xyz
# and save images to tar.gz file according to specific HOTFIXVERSION name, then upload packages to certain path of oss server
# see usage function for how to run.
#
# hack/
# └── auto_hotfix
#     └── hotfix.sh

function usage {
  echo -e "Usage:"
  echo -e " bash hotfix.sh [CHOICE] [UPLOAD_OSS_PATH] [HOTFIX_YAML_PATH]"
  echo -e ""
  echo -e " The script sync hotfix images from cargo-infra.caicloud.xyz to harbor.caicloud.xyz"
  echo -e " and save images to tar.gz file, then upload packages to certain path of oss server"
  echo -e ""
  echo -e "Parameter:"
  echo -e " CHOICE\t param to choose making hotfix or uploading hotfix"
  echo -e " UPLOAD_OSS_PATH\t the path of hotfix yaml"
  echo -e " HOTFIX_YAML_PATH\t the path to upload hotfix packages"
  echo -e ""
  echo -e "Example:"
  echo -e " make hotfix"
  echo -e "     bash hotfix.sh hotfix /path/of/product-release/release-hotfixes/2.7.1/20180907"
  echo -e "     will save hotfixes to ./hotfixes"
  echo -e " upload hotfix"
  echo -e "     bash hotfix.sh upload compass-v2.7.1-ga/ "
  echo -e "     will upload to oss://infra-release/platform/compass-v2.7.1-ga/hotfixes/20180907/..."
}
# -----------------------------------------------------------------------------
# Parameters for syncing docker and saving images, see usage.
# -----------------------------------------------------------------------------
#

CHOICE=$1
CHOICE=${CHOICE:=hotfix}

HOTFIX_LISTS_SUFFIX="compass-hotfixes"
TARGET_PATH="./hotfixes"

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

function makeHotfix(){
    # if the path end with .yaml, start parsing the yaml and saving image
    if [ "${1##*.}" = "yaml" ]; then
    echo -e "$GREEN_COL ########## handling ${1} ##########$NORMAL_COL"
    images=$( cat "${1}" | grep -e "image:.*" | grep -o "/.*" | sed $'s/\'//g' | sed $'s/\///g')
    for image in ${images[@]}
    do
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
    done
    elif [ -d $1 ]
    then
        for element in `ls $1`
        do
            dir_or_file=$1"/"$element
            # go on with function until got yaml
            makeHotfix $dir_or_file
        done
    # if the file end with .md, then cp this file
    elif [ "${1##*.}" = "md" ]; then
        cp "${1}" "${TARGET_PATH}"
    else
        echo -e "$RED_COL Getting hotfix yamls failed $NORMAL_COL"
        exit 1
    fi
}

case $CHOICE in
  # sync images
  hotfix )
    echo -e "$GREEN_COL start making hotfixes $NORMAL_COL"
    HOTFIX_YAML_PATH=$2
    # delete the "/" end of path
    HOTFIX_YAML_PATH=`echo ${HOTFIX_YAML_PATH%*/}`
    # get compass version by parsing the path
    COMPASS_VERSION=`echo $HOTFIX_YAML_PATH | grep -o -e "release-hotfixes/.*/" | awk -F '/' '{print$2}'`
    # source env.sh
    if [ -f ./env.sh ];then
    source ./env.sh
    else
    echo -e "$RED_COL env file not exist $NORMAL_COL"
    exit 1
    fi
    rm -rf $TARGET_PATH
    mkdir $TARGET_PATH
    makeHotfix "${HOTFIX_YAML_PATH}"
    ;;
  # upload the hotfix
  upload )
    echo -e "$GREEN_COL start uploading $NORMAL_COL"
    UPLOAD_OSS_PATH=$2
    # delete the "/" end of path
    UPLOAD_OSS_PATH=`echo ${UPLOAD_OSS_PATH%*/}`
    if [[ "`ls -A ${TARGET_PATH} | grep ${HOTFIX_LISTS_SUFFIX}`" = "" ]]; then
        echo -e "$RED_COL Getting hotfix packages failed $NORMAL_COL"
    else
        for file in `ls ${TARGET_PATH}`
        do
        FULL_UPLOAD_PATH="oss://infra-release/platform/${UPLOAD_OSS_PATH}/hotfixes/`date +%Y%m%d`/${file}"
        echo -e "$GREEN_COL uploading ${file} to ${FULL_UPLOAD_PATH}...... $NORMAL_COL"
        # upload to oss, need to set configuration on "~" path
        ~/ossutil cp -ru "${TARGET_PATH}/${file}" ${FULL_UPLOAD_PATH}
        done
    fi
    ;;
  * )
    echo -e "$RED_COL unknown param:${CHOICE} $NORMAL_COL"
    exit 1
    ;;
esac


