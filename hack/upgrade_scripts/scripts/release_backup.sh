#!/bin/bash
BASE_ROOT=$1
BASE_ROOT=${BASE_ROOT:=`pwd`}

GREEN_COL="\\033[32;1m"         # green color
YELLOW_COL="\\033[33;1m"        # yellow color
RED_COL="\\033[1;31m"           # red color
NORMAL_COL="\\033[0;39m"
CONFIG_PATH="${BASE_ROOT}/../../.kubectl.kubeconfig"
KUBECTL_PATH="${BASE_ROOT}/scripts/kubectl"
UPGRADE_CONFIG_PATH="${BASE_ROOT}/scripts/config"

# check kubeconfig
if [ -f ${CONFIG_PATH} ];then
echo -e "$GREEN_COL starting...... $NORMAL_COL"
else
echo -e "$RED_COL kubeconfig file \"${CONFIG_PATH}\" not exist $NORMAL_COL"
exit 1
fi

#source upgrade config
if [ -f ${UPGRADE_CONFIG_PATH} ];then
source ${UPGRADE_CONFIG_PATH}
else
echo -e "$RED_COL Upgrade config file not exist $NORMAL_COL"
exit 1
fi

resources_backup() {
    all_cluster=`${KUBECTL_PATH} get cluster --no-headers --kubeconfig=${CONFIG_PATH} | awk '{print $1}'`
    if [ -n "$all_cluster" ];then
    for clusterName in ${all_cluster}
    do
        echo -e "$YELLOW_COL backup resources for cluster ${clusterName}..... $NORMAL_COL"

        cluser_info=`${KUBECTL_PATH} get cluster ${clusterName} -o yaml --kubeconfig=${CONFIG_PATH}`

        # get endpointIP
        endpointIP=`echo ${cluser_info} | grep -oE 'endpointIP:.*' | awk '{print $2}'`

        # get endpointPort
        endpointPort=`echo ${cluser_info} | grep -oE 'endpointPort:.*' | awk '{print $2}' | sed 's/\"//g'`

        # get kubeUser
        kubeUser=`echo ${cluser_info} | grep -oE 'kubeUser:.*' | awk '{print $2}'`

        # get kubePassword
        kubePassword=`echo ${cluser_info} | grep -oE 'kubePassword:.*' | awk '{print $2}'`

        # generate kubeconfig for user-clusters
        new_kubeconfig=`cat templates/kubeconfig-v2.7.2.j2 | sed "s|endpointIP:endpointPort|${endpointIP}:${endpointPort}|g" | sed "s|clusterName|${clusterName}|g" | sed "s|kubeUser|${kubeUser}|g" | sed "s|kubePassword|${kubePassword}|g" > kubeconfig`

        mkdir -p "${BASE_ROOT}/backup_list"
        file_name="${BASE_ROOT}/backup_list/${clusterName}.txt"
        # get all original resources
        ${KUBECTL_PATH} --kubeconfig=kubeconfig get all --all-namespaces --no-headers | awk '{print$1,$2}' | awk -F '/' '{print $1,$2}' | sed '/^$/d' > ${file_name}

        back_items=`(echo $BACKUP_ITEMS | sed 's/,/ /g')`
        for back_item in ${back_items}
        do
            ${KUBECTL_PATH} get ${back_item} --no-headers --kubeconfig=kubeconfig | awk '{print"default","'"${back_item}"'",$1}' >> ${file_name}
        done

        n_back_items=`(echo $NAMESPACED_BACKUP_ITEMS | sed 's/,/ /g')`
        for n_back_item in ${n_back_items}
        do
            ${KUBECTL_PATH} get ${n_back_item} --all-namespaces --no-headers --kubeconfig=kubeconfig | awk '{print$1,"'"${n_back_item}"'",$2}' >> ${file_name}
        done

        cat ${file_name} | while read line
        do
            namespace=`echo ${line} | awk '{print$1}'`
            kind=`echo ${line} | awk '{print$2}' | sed 's/.apps//g;s/.batch//g'`
            name=`echo ${line} | awk '{print$3}'`
            echo "kubectl get ${kind} ${name} -n ${namespace}"
            mkdir -p ${BASE_ROOT}/release_backup/${clusterName}/${namespace}/${kind}/
            ${KUBECTL_PATH} --kubeconfig=kubeconfig -n ${namespace} get ${kind} ${name} -o yaml > ${BASE_ROOT}/release_backup/${clusterName}/${namespace}/${kind}/${name}.yaml
        done
	rm -rf kubeconfig
    done
    else
    echo -e "$RED_COL no cluster, exit...... $NORMAL_COL"
    exit 1
    fi

}

resources_backup
