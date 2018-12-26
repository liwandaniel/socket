#!/bin/bash

GREEN_COL="\\033[32;1m"         # green color
RED_COL="\\033[1;31m"           # red color
YELLOW_COL="\\033[33;1m"        # yellow color
NORMAL_COL="\\033[0;39m"

# chart lint image version
LINT_IMAGE="cargo.caicloudprivatetest.com/caicloud/chart-lint:v0.0.1"

function usage {
  echo -e "Usage:"
  echo -e "$YELLOW_COL bash chart-lint.sh [CHART_PATH] $NORMAL_COL"
  echo -e ""
  echo -e " The script check chart yaml by using release-cli chart lint from certain path"
  echo -e ""
  echo -e "Parameter:"
  echo -e " CHART_PATH\tthe path of chart yaml which will be check"
  echo -e ""
  echo -e "Example:"
  echo -e " bash chart-list.sh addons"
}

CHART_PATH=$1

# print the usage.
if [[ ! -n "$1" || "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
usage
exit 1
fi

# Try relative path
if [ -e "`pwd`/${CHART_PATH}" ];then
echo -e "$GREEN_COL lint chart from path `pwd`/${CHART_PATH} $NORMAL_COL"
MOUNT_PATH="`pwd`/${CHART_PATH}"
# Try absolute path
elif [ -e "${CHART_PATH}" ];then
echo -e "$GREEN_COL lint chart from path ${CHART_PATH} $NORMAL_COL"
MOUNT_PATH="${CHART_PATH}"
# Exit if path not found
else
echo -e "$RED_COL chart path not exists $NORMAL_COL"
exit 1
fi

echo -e "$GREEN_COL start lint charts $NORMAL_COL"

CONTAINER_PATH="/release-cli/addons/"

# if the CHART_PATH is yaml, mount yaml into container
if [ "${MOUNT_PATH##*.}" = "yaml" ]; then
YAML_NAME=`echo ${MOUNT_PATH} | awk -F'/' '{print $NF}'`
CONTAINER_PATH="/release-cli/addons/${YAML_NAME}"
fi

docker run --rm -it \
  -v ${MOUNT_PATH}:${CONTAINER_PATH} \
  ${LINT_IMAGE} \
  sh -c 'bash hack/lint/lint.sh addons'