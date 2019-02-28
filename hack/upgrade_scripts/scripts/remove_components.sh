#!/bin/bash
BASE_ROOT=$1
BASE_ROOT=${BASE_ROOT:=`pwd`}

GREEN_COL="\\033[32;1m"
NORMAL_COL="\\033[0;39m"
YELLOW_COL="\\033[33;1m"
RED_COL="\\033[1;31m"
CONFIG_PATH="${BASE_ROOT}/../../.kubectl.kubeconfig"
CARGO_ENV_PATH="${BASE_ROOT}/../../.install-env.sh"
KUBECTL_PATH="${BASE_ROOT}/scripts/kubectl"
UPGRADE_CONFIG_PATH="${BASE_ROOT}/scripts/config"
TEMPLATE_PATH="${BASE_ROOT}/templates"

# check kubeconfig
if [ -f ${CONFIG_PATH} ];then
echo -e "$GREEN_COL starting...... $NORMAL_COL"
else
echo -e "$RED_COL kubeconfig file \"${CONFIG_PATH}\" not exist $NORMAL_COL"
exit 1
fi

#source cargo env
if [ -f ${CARGO_ENV_PATH} ];then
source ${CARGO_ENV_PATH}
else
echo -e "$RED_COL Cargo env file not exist $NORMAL_COL"
exit 1
fi

#source upgrade config
if [ -f ${UPGRADE_CONFIG_PATH} ];then
source ${UPGRADE_CONFIG_PATH}
else
echo -e "$RED_COL Upgrade config file not exist $NORMAL_COL"
exit 1
fi

# remove components in default namespaces
remove_default() {
    default_component_arr=`(echo $REMOVE_COMPONENT_DEFAULT | sed 's/,/ /g')`

    for component in ${default_component_arr}
    do
    echo -e "$GREEN_COL remove release $component $NORMAL_COL"
    ${KUBECTL_PATH} delete release $component --kubeconfig=${CONFIG_PATH}
    done
}

# remove components in kube-system namespaces
remove_ks() {
    ks_component_arr=`(echo $REMOVE_COMPONENT_KS | sed 's/,/ /g')`

    all_cluster=`${KUBECTL_PATH} get cluster --no-headers --kubeconfig=${CONFIG_PATH} | awk '{print $1}'`
    if [ -n "$all_cluster" ];then
    for clusterName in ${all_cluster}
    do
        echo -e "$YELLOW_COL dealing with cluster ${clusterName}...... $NORMAL_COL"
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

        # apply release-controller deployment
        echo -e "$GREEN_COL replacing release-controller for cluster ${clusterName} $NORMAL_COL"
        cat ${TEMPLATE_PATH}/release_controller_dp.yaml.j2 | sed "s/\[\[ registry_release \]\]/${CARGO_CFG_DOMAIN}\/release/g" \
        | ${KUBECTL_PATH} --kubeconfig=kubeconfig apply -f -
        docker run -v ${BASE_ROOT}/kubeconfig:/kubeconfig harbor.caicloud.xyz/release/replace:v0.0.1 --kubeconfig=/kubeconfig

        for component in ${ks_component_arr}
        do
            echo -e "$GREEN_COL removing release $component ... $NORMAL_COL"
            ${KUBECTL_PATH} delete release $component --kubeconfig=kubeconfig -n kube-system
        done
	rm -rf kubeconfig
    done
    else
    echo -e "$RED_COL no cluster, exit...... $NORMAL_COL"
    exit 1
    fi
}

remove_default
remove_ks