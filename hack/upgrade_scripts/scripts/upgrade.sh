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
IMGAE_PATH="${BASE_ROOT}/images"
RELEASE_REGISTRY="harbor.caicloud.xyz"
IMAGE_TAR_SUFFIX=".tar.gz"
ADDON_MASTER_PORT="6009"
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

# delete am-master, am-minion, am-mysql of default namespace and create it by component installation
handle_am() {
    ${KUBECTL_PATH} delete svc am-master am-minion am-mysql --kubeconfig=${CONFIG_PATH}
    ${KUBECTL_PATH} delete deploy am-master am-minion am-mysql --kubeconfig=${CONFIG_PATH}
    ${KUBECTL_PATH} delete pvc am-mysql-data --kubeconfig=${CONFIG_PATH}
    ${KUBECTL_PATH} delete svc am-minion -n kube-system --kubeconfig=${CONFIG_PATH}
    ${KUBECTL_PATH} delete deploy am-minion release-controller -n kube-system --kubeconfig=${CONFIG_PATH}
}

# load all images under folder and push to cargo
handle_images() {
    echo -e "$YELLOW_COL loading images...... $NORMAL_COL"
    cd $IMGAE_PATH
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
handle_cluster() {
    controller_cluster=`${KUBECTL_PATH} get cluster --no-headers --kubeconfig=${CONFIG_PATH} | grep -v "user" | awk '{print $1}'`
    # get controller_cluster endpointIP
    controller_endpointIP=`${KUBECTL_PATH} get cluster ${controller_cluster} -o yaml --kubeconfig=${CONFIG_PATH} | grep -e 'endpointIP:' | awk '{print $2}'`
    
    user_cluster=`${KUBECTL_PATH} get cluster --no-headers --kubeconfig=${CONFIG_PATH} | grep 'user' | awk '{print $1}'`
    if [ -n "$user_cluster" ];then
    for clusterName in ${user_cluster}
    do
        echo -e "$YELLOW_COL dealing with cluster ${clusterName}...... \n $NORMAL_COL"
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
        new_kubeconfig=`cat templates/kubeconfig.j2 | sed "s|endpointIP:endpointPort|${endpointIP}:${endpointPort}|g" | sed "s|clusterName|${clusterName}|g" | sed "s|kubeUser|${kubeUser}|g" | sed "s|kubePassword|${kubePassword}|g" > kubeconfig`

        # replace am-minion deployment and service
        echo -e "$GREEN_COL replacing am-minion for cluster ${controller_cluster} $NORMAL_COL"

        # apply am-minion deployment
        ${KUBECTL_PATH} --kubeconfig=kubeconfig -n kube-system delete deployment `${KUBECTL_PATH} --kubeconfig=kubeconfig -n kube-system get deployment | grep am-minion | awk '{print $1}'`
        cat ${TEMPLATE_PATH}/am_minion_ks_dp.yaml.j2 | sed "s/\[\[ registry_release \]\]/${CARGO_CFG_DOMAIN}\/release/g" \
        | sed "s/\[\[ addon_master_ip \]\]/${controller_endpointIP}/g" \
        | sed "s/\[\[ addon_master_port \]\]/${ADDON_MASTER_PORT}/g" | ${KUBECTL_PATH} --kubeconfig=kubeconfig apply -f -

        # apply am-minion service
        ${KUBECTL_PATH} --kubeconfig=kubeconfig -n kube-system delete service `${KUBECTL_PATH} --kubeconfig=kubeconfig -n kube-system get service | grep am-minion | awk '{print $1}'`
        cat ${TEMPLATE_PATH}/am_minion_ks_svc.yaml.j2 | ${KUBECTL_PATH} --kubeconfig=kubeconfig apply -f -

        # replace release-controller deployment
        echo -e "$GREEN_COL replacing release-controller for cluster ${controller_cluster} $NORMAL_COL"

        # apply release-controller deployment
        cat ${TEMPLATE_PATH}/release_controller_dp.yaml.j2 | sed "s/\[\[ registry_release \]\]/${CARGO_CFG_DOMAIN}\/release/g" \
        | ${KUBECTL_PATH} --kubeconfig=kubeconfig apply -f -

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
handle_cluster

