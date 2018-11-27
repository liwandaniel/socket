#!/bin/bash

GREEN_COL="\\033[32;1m"         # green color
NORMAL_COL="\\033[0;39m"
config_path=../../.kubectl.kubeconfig


release_backup() {
    releases_default=`./kubectl get release --kubeconfig=$config_path | awk '{print $1}' | awk 'NR>1'`

    mkdir -p release_backup/default
    for default_release in ${releases_default}
    do
        echo -e "#################### dealing with release ${default_release} ####################"

        ./kubectl get release ${default_release} --kubeconfig=$config_path -o yaml > release_backup/default/${default_release}.yaml

        echo -e "$GREEN_COL release ${default_release} successfully saved $NORMAL_COL"
    done

    mkdir -p release_backup/kube-system
    releases_kube_system=`./kubectl get release -n kube-system --kubeconfig=$config_path | awk '{print $1}' | awk 'NR>1'`

    for kube_system_release in ${releases_kube_system}
    do
        echo -e "#################### dealing with release ${kube_system_release} ####################"

        ./kubectl get release ${kube_system_release} --kubeconfig=$config_path -n kube-system -o yaml > release_backup/kube-system/${kube_system_release}.yaml

        echo -e "$GREEN_COL release ${kube_system_release} successfully saved $NORMAL_COL"
    done

}

release_backup
