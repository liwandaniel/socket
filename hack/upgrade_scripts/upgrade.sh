#!/bin/bash

GREEN_COL="\\033[32;1m"
NORMAL_COL="\\033[0;39m"
YELLOW_COL="\\033[33;1m"
RED_COL="\\033[1;31m"
config_path="../../.kubectl.kubeconfig"
BASE_ROOT=$(cd $(dirname "${BASH_SOURCE}")/ && pwd -P)
SCRIPT_ROOT="${BASE_ROOT}/images"
RELEASE_REGISTRY="harbor.caicloud.xyz"
IMAGE_TAR_SUFFIX=".tar.gz"
ADDON_MASTER_PORT="6009"

# check kubeconfig
if [ -f $config_path ];then
echo -e "$GREEN_COL starting...... $NORMAL_COL"
else
echo -e "$RED_COL kubeconfig file \"${config_path}\" not exist $NORMAL_COL"
exit 1
fi

#source cargo env
if [ -f ../../.install-env.sh ];then
source ../../.install-env.sh
else
echo -e "$RED_COL Cargo env file not exist $NORMAL_COL"
exit 1
fi

# delete am-master, am-minion, am-mysql of default namespace and create it by component installation
handle_am() {
    ./kubectl delete svc am-master am-minion am-mysql --kubeconfig=$config_path
    ./kubectl delete deploy am-master am-minion am-mysql --kubeconfig=$config_path
    ./kubectl delete pvc am-mysql-data --kubeconfig=$config_path
    ./kubectl delete svc am-minion -n kube-system --kubeconfig=$config_path
    ./kubectl delete deploy am-minion release-controller -n kube-system --kubeconfig=$config_path
}

# load all images under folder and push to cargo
handle_images() {
    echo -e "$YELLOW_COL loading images...... $NORMAL_COL"
    cd $SCRIPT_ROOT
    IMAGE_TARS=$(ls | grep "${IMAGE_TAR_SUFFIX}" | xargs )

    for IMAGE_TAR in ${IMAGE_TARS[@]}
    do
        OLD_IMAGE=$(docker load -i $IMAGE_TAR | grep 'Loaded image: ' | sed 's/Loaded image://g')
        NEW_IMAGE=$(echo ${OLD_IMAGE} | sed "s/${RELEASE_REGISTRY}/${CARGO_CFG_DOMAIN}/g")
        docker tag ${OLD_IMAGE} ${NEW_IMAGE}
        docker push ${NEW_IMAGE}
    done
    echo -e "$GREEN_COL images loaded \n $NORMAL_COL"
    cd $BASE_ROOT
}

# replace the deployment of all user clusters
handole_cluster() {
    controller_cluster=`./kubectl get cluster --no-headers --kubeconfig=$config_path | grep -v "user" | awk '{print $1}'`
    # get controller_cluster endpointIP
    controller_endpointIP=`./kubectl get cluster ${controller_cluster} -o yaml --kubeconfig=$config_path | grep -e 'endpointIP:' | awk '{print $2}'`
    
    user_cluster=`./kubectl get cluster --no-headers --kubeconfig=$config_path | grep 'user' | awk '{print $1}'`
    if [ -n "$user_cluster" ];then
    for clusterName in ${user_cluster}
    do
        echo -e "$YELLOW_COL dealing with cluster ${clusterName}...... \n $NORMAL_COL"
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
        new_kubeconfig=`cat templates/kubeconfig.j2 | sed "s|endpointIP:endpointPort|${endpointIP}:${endpointPort}|g" | sed "s|clusterName|${clusterName}|g" | sed "s|kubeUser|${kubeUser}|g" | sed "s|kubePassword|${kubePassword}|g" > kubeconfig`

        # replace am-minion deployment and service
        echo -e "$GREEN_COL replacing am-minion for cluster ${controller_cluster} $NORMAL_COL"

        # apply am-minion deployment
        ./kubectl --kubeconfig=kubeconfig -n kube-system delete deployment `./kubectl --kubeconfig=kubeconfig -n kube-system get deployment | grep am-minion | awk '{print $1}'`
        cat templates/am_minion_ks_dp.yaml.j2 | sed "s/\[\[ registry_release \]\]/${CARGO_CFG_DOMAIN}\/release/g" \
        | sed "s/\[\[ addon_master_ip \]\]/${controller_endpointIP}/g" \
        | sed "s/\[\[ addon_master_port \]\]/${ADDON_MASTER_PORT}/g" | ./kubectl --kubeconfig=kubeconfig apply -f -

        # apply am-minion service
        ./kubectl --kubeconfig=kubeconfig -n kube-system delete service `./kubectl --kubeconfig=kubeconfig -n kube-system get service | grep am-minion | awk '{print $1}'`
        cat templates/am_minion_ks_svc.yaml.j2 | ./kubectl --kubeconfig=kubeconfig apply -f -

        # replace release-controller deployment
        echo -e "$GREEN_COL replacing release-controller for cluster ${controller_cluster} $NORMAL_COL"

        # apply release-controller deployment
        cat templates/release_controller_dp.yaml.j2 | sed "s/\[\[ registry_release \]\]/${CARGO_CFG_DOMAIN}\/release/g" \
        | ./kubectl --kubeconfig=kubeconfig apply -f -

        echo -e "$GREEN_COL cluster ${controller_cluster} successfully updated \n $NORMAL_COL"

	rm -rf kubeconfig
    done
    else
    echo -e "$RED_COL no user cluster, exit...... $NORMAL_COL"
    exit 1
    fi
}

handle_am
handle_images
handole_cluster

