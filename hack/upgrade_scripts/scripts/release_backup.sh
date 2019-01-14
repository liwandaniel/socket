#!/bin/bash
BASE_ROOT=$1
BASE_ROOT=${BASE_ROOT:=`pwd`}

GREEN_COL="\\033[32;1m"         # green color
YELLOW_COL="\\033[33;1m"        # yellow color
NORMAL_COL="\\033[0;39m"
CONFIG_PATH="${BASE_ROOT}/../../.kubectl.kubeconfig"
KUBECTL_PATH="${BASE_ROOT}/scripts/kubectl"


release_backup() {
    all_cluster=`${KUBECTL_PATH} get cluster --no-headers --kubeconfig=${CONFIG_PATH} | awk '{print $1}'`
    if [ -n "$all_cluster" ];then
    for clusterName in ${all_cluster}
    do
        echo -e "$YELLOW_COL#################### backup releases for cluster ${clusterName} #################### $NORMAL_COL"

        cluser_info=`${KUBECTL_PATH} get cluster ${clusterName} -o yaml --kubeconfig=${CONFIG_PATH}`

        # get endpointIP
        endpointIP=`echo ${cluser_info} | grep -oE 'endpointIP:.*' | awk '{print $2}'`

        # get endpointPort
        endpointPort=`echo ${cluser_info} | grep -oE 'endpointPort:.*' | awk '{print $2}' | sed 's/\"//g'`

        # get cluster-info
        authorityData=`echo ${cluser_info} | grep -oE 'certificate-authority-data:.*' | awk '{print $2}'`

        certificateData=`echo ${cluser_info} | grep -oE 'client-certificate-data:.*' | awk '{print $2}'`

        keyData=`echo ${cluser_info}| grep -oE 'client-key-data:.*' | awk '{print $2}'`

        # generate kubeconfig for user-clusters
        new_kubeconfig=`cat templates/kubeconfig.j2 | sed "s|endpointIP:endpointPort|${endpointIP}:${endpointPort}|g;s|clusterName|${clusterName}|g" \
        | sed "s|authorityData|${authorityData}|g;s|certificateData|${certificateData}|g;s|keyData|${keyData}|g" > kubeconfig`

        releases_default=`${KUBECTL_PATH} get release --kubeconfig=kubeconfig | grep -v NAME | awk '{print $1}'`

        mkdir -p ${BASE_ROOT}/release_backup/${clusterName}/default
        for default_release in ${releases_default}
        do
            echo -e "#################### dealing with release ${default_release} ####################"

            ${KUBECTL_PATH} get release ${default_release} --kubeconfig=kubeconfig -o yaml > ${BASE_ROOT}/release_backup/${clusterName}/default/${default_release}.yaml

            echo -e "$GREEN_COL release ${default_release} successfully saved $NORMAL_COL"
        done

        mkdir -p ${BASE_ROOT}/release_backup/${clusterName}/kube-system
        releases_kube_system=`${KUBECTL_PATH} get release -n kube-system --kubeconfig=kubeconfig | awk '{print $1}' | awk 'NR>1'`

        for kube_system_release in ${releases_kube_system}
        do
            echo -e "#################### dealing with release ${kube_system_release} ####################"

            ${KUBECTL_PATH} get release ${kube_system_release} --kubeconfig=kubeconfig -n kube-system -o yaml > ${BASE_ROOT}/release_backup/${clusterName}/kube-system/${kube_system_release}.yaml

            echo -e "$GREEN_COL release ${kube_system_release} successfully saved $NORMAL_COL"
        done

	rm -rf kubeconfig
    done
    else
    echo -e "$RED_COL no cluster, exit...... $NORMAL_COL"
    exit 1
    fi

}

release_backup
