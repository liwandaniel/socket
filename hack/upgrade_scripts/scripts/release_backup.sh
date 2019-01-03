#!/bin/bash
BASE_ROOT=$1
BASE_ROOT=${BASE_ROOT:=`pwd`}

GREEN_COL="\\033[32;1m"         # green color
NORMAL_COL="\\033[0;39m"
CONFIG_PATH="${BASE_ROOT}/../../.kubectl.kubeconfig"
KUBECTL_PATH="${BASE_ROOT}/scripts/kubectl"


release_backup() {
    releases_default=`${KUBECTL_PATH} get release --kubeconfig=${CONFIG_PATH} | grep -v NAME | awk '{print $1}'`

    mkdir -p ${BASE_ROOT}/release_backup/default
    for default_release in ${releases_default}
    do
        echo -e "#################### dealing with release ${default_release} ####################"

        ${KUBECTL_PATH} get release ${default_release} --kubeconfig=${CONFIG_PATH} -o yaml > ${BASE_ROOT}/release_backup/default/${default_release}.yaml

        echo -e "$GREEN_COL release ${default_release} successfully saved $NORMAL_COL"
    done

    mkdir -p ${BASE_ROOT}/release_backup/kube-system
    releases_kube_system=`${KUBECTL_PATH} get release -n kube-system --kubeconfig=${CONFIG_PATH} | awk '{print $1}' | awk 'NR>1'`

    for kube_system_release in ${releases_kube_system}
    do
        echo -e "#################### dealing with release ${kube_system_release} ####################"

        ${KUBECTL_PATH} get release ${kube_system_release} --kubeconfig=${CONFIG_PATH} -n kube-system -o yaml > ${BASE_ROOT}/release_backup/kube-system/${kube_system_release}.yaml

        echo -e "$GREEN_COL release ${kube_system_release} successfully saved $NORMAL_COL"
    done

}

release_backup
