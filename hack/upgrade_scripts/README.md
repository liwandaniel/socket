<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [升级包](#%E5%8D%87%E7%BA%A7%E5%8C%85)
- [compass 升级包](#compass-%E5%8D%87%E7%BA%A7%E5%8C%85)
  - [包结构](#%E5%8C%85%E7%BB%93%E6%9E%84)
  - [升级包组成](#%E5%8D%87%E7%BA%A7%E5%8C%85%E7%BB%84%E6%88%90)
- [如何使用升级包](#%E5%A6%82%E4%BD%95%E4%BD%BF%E7%94%A8%E5%8D%87%E7%BA%A7%E5%8C%85)
  - [备份控制集群 release](#%E5%A4%87%E4%BB%BD%E6%8E%A7%E5%88%B6%E9%9B%86%E7%BE%A4-release)
  - [升级组件](#%E5%8D%87%E7%BA%A7%E7%BB%84%E4%BB%B6)
  - [检查升级结果](#%E6%A3%80%E6%9F%A5%E5%8D%87%E7%BA%A7%E7%BB%93%E6%9E%9C)
  - [移除不需要的组件](#%E7%A7%BB%E9%99%A4%E4%B8%8D%E9%9C%80%E8%A6%81%E7%9A%84%E7%BB%84%E4%BB%B6)
  - [升级平台产品](#%E5%8D%87%E7%BA%A7%E5%B9%B3%E5%8F%B0%E4%BA%A7%E5%93%81)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

### 升级包

针对每个版本，compass 产品需要有升级方案，因此需要准备升级包来供前线或者研发来升级版本

最终完整的升级包包含 kernel 升级包 `compass-kernel-upgrade-2.x.x-2.x.x.tar`，以及 cargo 或者流水线升级包 `workspace-upgrade.tar.gz` 等其他升级需要的包

**最终完整包结构如下：**

```bash
$ tree compass-upgrade-2.x.x-2.x.x/
compass-upgrade-2.x.x-2.x.x/
├── compass-kernel-upgrade.tar.gz
├── comapss-component-upgrade.tar.gz
├── ...
└── workspace-upgrade.tar.gz
```

此处只做 compass 升级包的解释，即 `comapss-component-upgrade.tar.gz`

### compass 升级包

#### 包结构

```bash
$ tree comapss-component-upgrade/
comapss-component-upgrade/
├── scripts
│   ├── upgrade.sh
│   ├── check_image.sh
│   ├── release_backup.sh
│   ├── remove_components.sh
│   ├── config
│   └── kubectl
├── images
│   ├── am-minion-v0.0.7.tar.gz
│   ├── release-controller-v0.2.10.tar.gz
│   └── templates-v1.2.14.tar.gz
├── templates
│   ├── am_minion_ks_dp.yaml.j2
│   ├── release_controller.yaml.j2
│   └── kubeconfig.j2
└── run.sh
```

#### 升级包组成

- `run.sh`: 执行脚本
- `scripts`: 具体任务对应的脚本
    - upgrade.sh: 升级脚本
    - check_image.sh: 升级镜像检查
    - release_backup.sh: 备份控制集群 release
    - remove_components.sh: 移除不需要的组件
    - config: 升级需要的一些参数配置
    - kubectl
- `images`: 升级依赖的镜像
    - am-minion-xxx.tar.gz
    - release-controller-xxx.tar.gz
    - templates-xxx.tar.gz
- `templates`: 升级需要的模板文件
    - am_minion_ks_dp.yaml.j2: kube-system 分区下 am-minion 的 [deployment yaml](../../prerequisites/am_minion/am_minion_ks_dp.yaml.j2)
        - 注意，因为用户集群没有控制集群部署的 `am-master`，所以需要手动删除 `am_minion_ks_dp.yaml.j2` 文件的如下内容：
            ```bash
            initContainers:
            - name: check-master
              image: [[ registry_release ]]/am_minion:v0.0.7
              command: ["/bin/sh", "-c", "until /pangolin/kubectl get pods -n default | grep am-master | grep Running; do echo waiting for master to be ready; sleep 5; done;"]
            ```
    - release_controller.yaml.j2: kube-system 分区下 release_controller 的 [deployment yaml](../../prerequisites/release_controller/release_controller_dp.yaml.j2)
    - kubeconfig.j2: 生成用户集群 kubeconfig 的 [模板](templates/kubeconfig.j2)

将所有的文件打包成 compass 升级包 `comapss-component-upgrade.tar.gz`

与其他升级包一起打包成 `compass-upgrade-2.x.x-2.x.x.tar.gz`


### 如何使用升级包

参考 [升级文档](https://docs.google.com/document/d/1HZ3tQztb0-JppIPyYOT9ugV5NJpWCChrRkwNjRlFOiE/edit#heading=h.qjnv4y85l36x)

解压升级包

```bash
tar xvf compass-upgrade-2.7.0-2.7.1.tar.gz 
cd compass-upgrade-2.7.0-2.7.1 && tar xvf comapss-component-upgrade.tar.gz
cd comapss-component-upgrade
```

- 需要确保升级脚本的相对路径 ` ../../.install-env.sh` 和 `../../.kubectl.kubeconfig` 文件存在

#### 备份控制集群 release

```bash
bash run.sh backup
```

此脚本用于备份控制集群所有的 release 资源，运行之后会生成 release_backup 目录，其中分别保存了两个分区的 release 信息，default 和 kube-system

#### 升级组件

运行升级脚本

```bash
bash run.sh upgrade
```

#### 检查升级结果

```bash
$ bash run.sh check

am_minion:v0.0.7
release-controller:v0.2.10
```

检查升级后的镜像与最新版本是否一致

#### 移除不需要的组件

根据 config 文件的配置，组件名称为 release 的名称，区分 defalut 和 kube-system 并用 "," 分割

```bash
bash run.sh remove
```

#### 升级平台产品

之后按照标准产品的安装方式来升级版本

参考 [产品部署文档](https://docs.google.com/document/d/1hnEdqaDRbHsfLYf89kv_SEv0-RXCes4BF6oZU4ObeMY/edit#heading=h.2yy1aubfzm7r) 和 [部署指导](https://github.com/caicloud/product-release/blob/master/docs/product-installation.md#%E5%AE%89%E8%A3%85%E5%8C%85%E9%83%A8%E7%BD%B2)

