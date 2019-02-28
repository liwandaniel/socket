#!/bin/bash
# delete all resources and recreate
kubectl delete cm platform-info
kubectl delete cm platform-config
kubectl delete svc am-master am-mysql
kubectl delete deploy am-minion release-controller -n kube-system
kubectl delete deploy am-master am-minion am-mysql
kubectl delete pvc am-mysql-data
kubectl delete release -n kube-system `kubectl get release -n kube-system --no-headers | awk '{print $1}'`
kubectl delete release `kubectl get release --no-headers | awk '{print $1}'`
kubectl delete pvc `kubectl get pvc --no-headers | awk '{print $1}'`

while [ `/pangolin/kubectl get pods --no-headers | grep -v heketi | grep -v plugin | wc -l` -ge 1 ];
do echo "waiting for pods to be killed"; sleep 10; done;

# create secret for cargo
kubectl create secret docker-registry infra-cargo --docker-server=${SOURCE_REGISTRY} \
--docker-username=${SOURCE_REGISTRY_USER} --docker-password=${SOURCE_REGISTRY_PASSWORD} --docker-email=liwan@caicloud.io

kubectl -n kube-system create secret docker-registry infra-cargo-ks --docker-server=${SOURCE_REGISTRY} \
--docker-username=${SOURCE_REGISTRY_USER} --docker-password=${SOURCE_REGISTRY_PASSWORD} --docker-email=liwan@caicloud.io

# add secret into each serviceaccount
default_sas=`(kubectl get serviceaccount --no-headers | awk '{print$1}')`

for default_sa in ${default_sas}
do
    kubectl get serviceaccount ${default_sa} -o json | sed 's#"kind": "ServiceAccount",#"kind": "ServiceAccount",\n"imagePullSecrets": [\n{"name": "infra-cargo"\n}\n],#g' | kubectl apply -f -
done

ks_sas=`(kubectl -n kube-system get serviceaccount --no-headers | awk '{print$1}')`

for ks_sa in ${ks_sas}
do
    kubectl -n kube-system get serviceaccount ${ks_sa} -o json | sed 's#"kind": "ServiceAccount",#"kind": "ServiceAccount",\n"imagePullSecrets": [\n{"name": "infra-cargo-ks"\n}\n],#g' | kubectl -n kube-system apply -f -
done

# delete apiservice which caused crashing of release-controller
kubectl delete apiservice v1beta1.custom.metrics.k8s.io v1beta1.metrics.k8s.io

cp config.sample config

sed -i 's#{{ registryName }}#'${SOURCE_REGISTRY}'#g;s#/release#/'${SOURCE_PROJECT}'#g;s#{{ cargoName }}#'${SOURCE_REGISTRY}'#g' /pangolin/platform-info.yaml.j2
python3 amctl.py init all

sed -i 's/Pwd123456/'${SOURCE_REGISTRY_PASSWORD}'/g' /pangolin/addons/cargo/cargo-admin.yaml

until /pangolin/kubectl get pods | grep am-master | grep Running;
do echo "waiting for master to be ready"; sleep 5; done;

python3 amctl.py install -p /pangolin/addons/

