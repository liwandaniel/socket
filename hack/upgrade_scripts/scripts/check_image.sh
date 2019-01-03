#!/bin/bash
BASE_ROOT=$1
BASE_ROOT=${BASE_ROOT:=`pwd`}

GREEN_COL="\\033[32;1m"         # green color
NORMAL_COL="\\033[0;39m"
RED_COL="\\033[1;31m"
CONFIG_PATH="${BASE_ROOT}/../../.kubectl.kubeconfig"
KUBECTL_PATH="${BASE_ROOT}/scripts/kubectl"


handle_cluster() {
    all_cluster=`${KUBECTL_PATH} get cluster --no-headers --kubeconfig=${CONFIG_PATH} | awk '{print $1}'`
    if [ -n "$all_cluster" ];then
    for clusterName in ${all_cluster}
    do
        echo -e "$GREEN_COL#################### getting image version from cluster ${clusterName} #################### $NORMAL_COL"

        cluser_info=`${KUBECTL_PATH} get cluster ${clusterName} -o yaml --kubeconfig=${CONFIG_PATH}`

        # get endpointIP
        endpointIP=`echo ${cluser_info}| grep -oE 'endpointIP:.*' | awk '{print $2}'`

        # get endpointPort
        endpointPort=`echo ${cluser_info} | grep -oE 'endpointPort:.*' | awk '{print $2}' | sed 's/\"//g'`

        # get kubeUser
        kubeUser=`echo ${cluser_info} | grep -oE 'kubeUser:.*' | awk '{print $2}'`

        # get kubePassword
        kubePassword=`echo ${cluser_info} | grep -oE 'kubePassword:.*' | awk '{print $2}'`

        # generate kubeconfig for user-clusters
        new_kubeconfig=`cat templates/kubeconfig.j2 | sed "s|endpointIP:endpointPort|${endpointIP}:${endpointPort}|g" \
        | sed "s|clusterName|${clusterName}|g" | sed "s|kubeUser|${kubeUser}|g" | sed "s|kubePassword|${kubePassword}|g" > kubeconfig`

        # replace am-minion and release-controller
        ${KUBECTL_PATH} --kubeconfig=kubeconfig -n kube-system get deployment `${KUBECTL_PATH} --kubeconfig=kubeconfig get deployment -n kube-system \
        | grep am-minion | awk '{print $1}'` -o yaml | grep -oE 'am_minion:.*' | grep -v "{*}" | awk 'NR==1'

        ${KUBECTL_PATH} --kubeconfig=kubeconfig get deployment `${KUBECTL_PATH} --kubeconfig=kubeconfig get deployment -n kube-system \
        | grep ^release-controller | awk '{print $1}'` -o yaml -n kube-system | grep -oE 'release-controller:.*' | grep -v "{*}" | awk 'NR==1'
	rm -rf kubeconfig
    done
    else
    echo -e "$RED_COL no user cluster, exit...... $NORMAL_COL"
    exit 1
    fi
}

handle_cluster


