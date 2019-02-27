#!/bin/bash
kubectl delete cm platform-info
kubectl delete cm platform-config
kubectl delete svc am-master am-mysql
kubectl delete deploy am-minion release-controller -n kube-system
kubectl delete deploy am-master am-minion am-mysql
kubectl delete pvc am-mysql-data
kubectl delete release -n kube-system `kubectl get release -n kube-system --no-headers | awk '{print $1}'`
kubectl delete release `kubectl get release --no-headers | awk '{print $1}'`
kubectl delete pvc `kubectl get pvc --no-headers | awk '{print $1}'`
while kubectl get pods | grep -v heketi | grep -v plugin | grep Running; do echo 'waiting for pods to be killed'; sleep 10; done
kubectl delete apiservice v1beta1.custom.metrics.k8s.io v1beta1.metrics.k8s.io
echo "clean components done"
