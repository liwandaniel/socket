#!/bin/bash
input=$1
input=${input:=check}

GREEN_COL="\\033[32;1m"
NORMAL_COL="\\033[0;39m"
YELLOW_COL="\\033[33;1m"
RED_COL="\\033[1;31m"
SCRIPTS_DIR="./scripts"
BASE_ROOT=$(cd $(dirname "${BASH_SOURCE}")/ && pwd -P)

case $input in
  upgrade )
    echo -e "$GREEN_COL upgrading addons... $NORMAL_COL"
    bash $SCRIPTS_DIR/upgrade.sh ${BASE_ROOT}
    ;;
  check )
    echo -e "$GREEN_COL checking addons... $NORMAL_COL"
    bash $SCRIPTS_DIR/check_image.sh ${BASE_ROOT}
    ;;
  remove )
    echo -e "$GREEN_COL removing addons... $NORMAL_COL"
    bash $SCRIPTS_DIR/remove_components.sh ${BASE_ROOT}
    ;;
  backup )
    echo -e "$GREEN_COL removing addons... $NORMAL_COL"
    bash $SCRIPTS_DIR/release_backup.sh ${BASE_ROOT}
    ;;
  * )
    echo -e "$RED_COL unknown command $NORMAL_COL"
    exit 1
    ;;
esac



