#!/bin/bash

GREEN_COL="\\033[32;1m"         # green color
NORMAL_COL="\\033[0;39m"
RED_COL="\\033[1;31m"
config_path="../../.kubectl.kubeconfig"


handole_cluster() {
    user_cluster=`./kubectl get cluster --no-headers --kubeconfig=$config_path | awk '{print $1}'`
    if [ -n "$user_cluster" ];then
    for clusterName in ${user_cluster}
    do
        echo -e "$GREEN_COL#################### getting new image version from cluster ${clusterName} #################### $NORMAL_COL"

        cluser_info=`./kubectl get cluster ${clusterName} -o yaml --kubeconfig=$config_path`

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
        ./kubectl --kubeconfig=kubeconfig -n kube-system get deployment `./kubectl --kubeconfig=kubeconfig get deployment -n kube-system \
        | grep am-minion | awk '{print $1}'` -o yaml | grep -oE 'am_minion:.*' | awk 'NR==1'

        ./kubectl --kubeconfig=kubeconfig get deployment `./kubectl --kubeconfig=kubeconfig get deployment -n kube-system \
        | grep ^release-controller | awk '{print $1}'` -o yaml -n kube-system | grep -oE 'release-controller:.*'
	rm -rf kubeconfig
    done
    else
    echo -e "$RED_COL no user cluster, exit...... $NORMAL_COL"
    exit 1
    fi
}

handole_cluster


