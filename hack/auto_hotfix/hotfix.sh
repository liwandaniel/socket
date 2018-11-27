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

# get product name of current hotfix, default is compass
PRODUCT=$3
PRODUCT=${PRODUCT:=compass}

HOTFIX_LISTS_SUFFIX="${PRODUCT}-hotfixes"
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
        # make new dir in TARGET_PATH to save image and yaml
        ADDON_NAME=`cat "${1}" | grep -e "name:.*" | awk NR==1 | awk -F': ' '{print $2}'`
        HOTFIX_FULL_NAME="${HOTFIX_LISTS_SUFFIX}-${PRODUCT_VERSION}-"`date +%Y%m%d`"-${ADDON_NAME}"
        mkdir "${TARGET_PATH}/${HOTFIX_FULL_NAME}"
        cp "${1}" "${TARGET_PATH}/${HOTFIX_FULL_NAME}"
        # get all images from yaml
        images=$( cat "${1}" | grep -e "\[\[ registry_release \]\].*" | grep -o "/.*" | sed $'s/\'//g' | sed $'s/\///g')
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
                # save images
                echo -e "$GREEN_COL ${NEW_IMAGE} successfully pushed $NORMAL_COL"
                IMAGE_NAME=`echo $image | cut -d \: -f 1`
                IMAGE_TAG=`echo $image | cut -d \: -f 2`
                FULL_NAME="${HOTFIX_LISTS_SUFFIX}-${PRODUCT_VERSION}-"`date +%Y%m%d`"-${IMAGE_NAME}-${IMAGE_TAG}-image.tar.gz"
                echo -e "$GREEN_COL saving image to file ${FULL_NAME}...... $NORMAL_COL"
                docker save ${NEW_IMAGE} -o "${TARGET_PATH}/${HOTFIX_FULL_NAME}/${FULL_NAME}"
            fi
    cd ${TARGET_PATH} && tar cvf "${HOTFIX_FULL_NAME}.tar.gz" "${HOTFIX_FULL_NAME}"
    cd -
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
    PRODUCT_VERSION=`echo $HOTFIX_YAML_PATH | grep -o -e "release-hotfixes/.*/" | awk -F '/' '{print$2}'`
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
            if [ "${file##*.}" = "gz" ] || [ "${file##*.}" = "md"  ]; then
                FULL_UPLOAD_PATH="oss://infra-release/platform/${UPLOAD_OSS_PATH}/hotfixes/`date +%Y%m%d`/${file}"
                echo -e "$GREEN_COL uploading ${file} to ${FULL_UPLOAD_PATH}...... $NORMAL_COL"
                # upload to oss, need to set configuration on "~" path
                ~/ossutil cp -ru "${TARGET_PATH}/${file}" ${FULL_UPLOAD_PATH}
            else
                rm -rf "${TARGET_PATH}/${file}"
            fi
        done
    fi
    ;;
  * )
    echo -e "$RED_COL unknown param:${CHOICE} $NORMAL_COL"
    exit 1
    ;;
esac


