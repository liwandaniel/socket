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

# remove am-minion service after 2.7.3, recreate am-mysql by new installation to ensure data correct
handle_am() {
    ${KUBECTL_PATH} delete svc am-minion --kubeconfig=${CONFIG_PATH}
    ${KUBECTL_PATH} delete deploy am-mysql --kubeconfig=${CONFIG_PATH}
    ${KUBECTL_PATH} delete pvc am-mysql-data --kubeconfig=${CONFIG_PATH}
    ${KUBECTL_PATH} delete svc am-minion -n kube-system --kubeconfig=${CONFIG_PATH}
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
    
    all_cluster=`${KUBECTL_PATH} get cluster --no-headers --kubeconfig=${CONFIG_PATH} | awk '{print $1}'`
    if [ -n "$all_cluster" ];then
    for clusterName in ${all_cluster}
    do
        cluser_info=`${KUBECTL_PATH} get cluster ${clusterName} -o yaml --kubeconfig=${CONFIG_PATH}`

        isControlCluster=`echo ${cluser_info}| grep -oE 'isControlCluster:.*' | awk '{print $2}'`

        if [ "${isControlCluster}" != "true" ]; then

            echo -e "$YELLOW_COL dealing with cluster ${clusterName}...... \n $NORMAL_COL"

            # get endpointIP
            endpointIP=`echo ${cluser_info} | grep -oE 'endpointIP:.*' | awk '{print $2}'`

            # get endpointPort
            endpointPort=`echo ${cluser_info} | grep -oE 'endpointPort:.*' | awk '{print $2}' | sed 's/\"//g'`

            # get cluster-info
            authorityData=`echo ${cluser_info} | grep -oE 'certificate-authority-data:.*' | awk '{print $2}'`

            certificateData=`echo ${cluser_info} | grep -oE 'client-certificate-data:.*' | awk '{print $2}'`

            keyData=`echo ${cluser_info} | grep -oE 'client-key-data:.*' | awk '{print $2}'`

            # generate kubeconfig for user-clusters
            new_kubeconfig=`cat templates/kubeconfig.j2 | sed "s|endpointIP:endpointPort|${endpointIP}:${endpointPort}|g;s|clusterName|${clusterName}|g" \
            | sed "s|authorityData|${authorityData}|g;s|certificateData|${certificateData}|g;s|keyData|${keyData}|g" > kubeconfig`

            # replace am-minion deployment and service
            echo -e "$GREEN_COL replacing am-minion for cluster ${clusterName} $NORMAL_COL"

            # apply am-minion deployment
            cat ${TEMPLATE_PATH}/am_minion_ks_dp.yaml.j2 | sed "s/\[\[ registry_release \]\]/${CARGO_CFG_DOMAIN}\/release/g" \
            | sed "s/\[\[ addon_master_ip \]\]/${controller_endpointIP}/g" \
            | sed "s/\[\[ addon_master_port \]\]/${ADDON_MASTER_PORT}/g" | ${KUBECTL_PATH} --kubeconfig=kubeconfig apply -f -

            # delete am-minion service
            ${KUBECTL_PATH} --kubeconfig=kubeconfig -n kube-system delete service `${KUBECTL_PATH} --kubeconfig=kubeconfig -n kube-system get service | grep am-minion | awk '{print $1}'` &>/dev/null

            # replace release-controller deployment
            echo -e "$GREEN_COL replacing release-controller for cluster ${clusterName} $NORMAL_COL"

            # apply release-controller deployment
            cat ${TEMPLATE_PATH}/release_controller_dp.yaml.j2 | sed "s/\[\[ registry_release \]\]/${CARGO_CFG_DOMAIN}\/release/g" \
            | ${KUBECTL_PATH} --kubeconfig=kubeconfig apply -f -

            echo -e "$GREEN_COL cluster ${controller_cluster} successfully updated \n $NORMAL_COL"
        else
        echo -e "$YELLOW_COL cluster ${clusterName} is not user cluster, pass $NORMAL_COL"
        fi

	rm -rf kubeconfig
    done
    else
    echo -e "$RED_COL no cluster found, exit...... $NORMAL_COL"
    exit 1
    fi
}

handle_am
handle_images
handle_cluster

