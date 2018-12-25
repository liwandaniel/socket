#!/bin/bash

set -o nounset
set -o errexit

REGISTRY=$1
VERSION=$2
PANGOLIN_ROOT=$(cd $(dirname "${BASH_SOURCE}")/ && pwd -P)
PANGOLIN_HOTFIX=$PANGOLIN_ROOT/hotfixes
RELEASE_REGISTRY="harbor.caicloud.xyz"
HOTFIX_REGEX=".*hotfixes.*.tar.gz$"
IMAGE_TAR_SUFFIX="\-image.tar.gz"

handle_hotfix() {
	HOTFIX=$1
	echo "Handling hotfix: ${HOTFIX}"

	if [ -f release_controller_dp.yaml ]; then
		echo "Replace registry placeholder in release controller deployment"
		sed -i "s/\[\[ registry_release \]\]/$REGISTRY/g" release_controller_dp.yaml
	fi

	IMAGE_TARS=$(ls | grep "${IMAGE_TAR_SUFFIX}" | xargs )

	for IMAGE_TAR in ${IMAGE_TARS[@]}
	do
	        OLD_IMAGE=$(docker load -i $IMAGE_TAR | grep 'Loaded image: ' | sed 's/Loaded image://g')
	        NEW_IMAGE=$(echo ${OLD_IMAGE} | sed "s/${RELEASE_REGISTRY}/${REGISTRY}/g")
	        docker tag ${OLD_IMAGE} ${NEW_IMAGE}
	        docker push ${NEW_IMAGE}
	done
}

cd $PANGOLIN_HOTFIX

HOTFIX_TARS=$(ls | grep  "${HOTFIX_REGEX}" | xargs )
echo "Will handle hotfixes: ${HOTFIX_TARS}"

for HOTFIX_TAR in ${HOTFIX_TARS[@]}
do
	HOTFIX=$(echo ${HOTFIX_TAR} | sed 's/.tar.gz//g')
	tar xf $HOTFIX_TAR
	cd ${HOTFIX}
	handle_hotfix ${HOTFIX}
	cd -
done

cd $PANGOLIN_ROOT

docker run --rm -it \
  -v `pwd`/hotfixes:/pangolin/hotfixes \
  -v `pwd`/../.kubectl.kubeconfig:/root/.kube/config \
  ${REGISTRY}/release/pangolin:${VERSION} bash
