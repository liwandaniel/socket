#!/bin/bash
GREEN_COL="\\033[32;1m"         # green color
RED_COL="\\033[1;31m"           # red color
NORMAL_COL="\\033[0;39m"

mkdir -p /compass/cluster_status

echo -e "$GREEN_COL getting pods and nodes status... $NORMAL_COL"
kubectl get nodes -o wide > /compass/cluster_status/all_node_status.txt
kubectl get pods --all-namespaces -o wide > /compass/cluster_status/all_pods_status.txt

kubectl -n kube-system get cm apiserver-proxy-nginx-config -o yaml > /compass/cluster_status/apiserver-proxy-nginx-config.yaml
kubectl -n kube-system get cm apiserver-proxy-nginx-tcp -o yaml > /compass/cluster_status/apiserver-proxy-nginx-tcp.yaml
kubectl -n kube-system get cm apiserver-proxy-nginx-udp -o yaml > /compass/cluster_status/apiserver-proxy-nginx-udp.yaml

machine_name=`kubectl get machine --no-headers | awk '{print$1}' | awk "NR==1"`

echo -e "$GREEN_COL checking etcd status... $NORMAL_COL"
apiserver_name=`kubectl -n kube-system get pods | grep kube-apiserver | awk '{print$1}' | awk 'NR==1'`
etcd_addrs=`(kubectl -n kube-system get pods ${apiserver_name} -o yaml | grep -o "etcd-servers=.*" | awk -F ',' '{print $1,$2,$3}')`

echo -e "$GREEN_COL checking gluster status... $NORMAL_COL"
gluster volume status > /compass/cluster_status/gluster_vol_status.txt

master_ip=`echo ${etcd_addrs} | awk '{print$1}' | awk -F ':' '{print$2}' | sed 's#/##g'`

echo -e "$GREEN_COL backup etcd... $NORMAL_COL"

ETCDCTL_API=3 /usr/local/etcd/bin/etcdctl --cacert=/var/lib/etcd/ssl/ca.crt --cert=/var/lib/etcd/ssl/etcd.crt --key=/var/lib/etcd/ssl/etcd.key --endpoints=https://${master_ip}:2379 snapshot save /compass/cluster_status/etcd-2379-snapshot-`date +"%Y-%m-%d-%H-%M-%S"`.db

ETCDCTL_API=3 /usr/local/etcd/bin/etcdctl --cacert=/var/lib/etcd/ssl/ca.crt --cert=/var/lib/etcd/ssl/etcd.crt --key=/var/lib/etcd/ssl/etcd.key --endpoints=https://${master_ip}:2381 snapshot save /compass/cluster_status/etcd-2381-snapshot-`date +"%Y-%m-%d-%H-%M-%S"`.db

for etcd_addr in ${etcd_addrs}
do
    etcd_addr=`echo ${etcd_addr} | awk -F ':' '{print$2}' | sed 's#/##g'`
    ETCDCTL_API=3 /usr/local/etcd/bin/etcdctl --cacert=/var/lib/etcd/ssl/ca.crt --cert=/var/lib/etcd/ssl/etcd.crt --key=/var/lib/etcd/ssl/etcd.key --endpoints=https://${etcd_addr}:2379 member list

    echo -e "$GREEN_COL checking ca for apiserver status... $NORMAL_COL"
    ssh root@${etcd_addr} "cat /etc/kubernetes/certs/ca.crt >> /etc/pki/tls/certs/ca-bundle.crt"
done
