<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [简介](#%E7%AE%80%E4%BB%8B)
  - [安装包部署](#%E5%AE%89%E8%A3%85%E5%8C%85%E9%83%A8%E7%BD%B2)
    - [准备工作](#%E5%87%86%E5%A4%87%E5%B7%A5%E4%BD%9C)
    - [开始安装](#%E5%BC%80%E5%A7%8B%E5%AE%89%E8%A3%85)
    - [debug 模式修改 release](#debug-%E6%A8%A1%E5%BC%8F%E4%BF%AE%E6%94%B9-release)
  - [镜像部署](#%E9%95%9C%E5%83%8F%E9%83%A8%E7%BD%B2)
    - [镜像启动](#%E9%95%9C%E5%83%8F%E5%90%AF%E5%8A%A8)
    - [创建 config](#%E5%88%9B%E5%BB%BA-config)
    - [安装产品](#%E5%AE%89%E8%A3%85%E4%BA%A7%E5%93%81)
  - [分步安装](#%E5%88%86%E6%AD%A5%E5%AE%89%E8%A3%85)
    - [依赖安装](#%E4%BE%9D%E8%B5%96%E5%AE%89%E8%A3%85)
    - [应用部署](#%E5%BA%94%E7%94%A8%E9%83%A8%E7%BD%B2)
  - [升级组件](#%E5%8D%87%E7%BA%A7%E7%BB%84%E4%BB%B6)
  - [卸载组件](#%E5%8D%B8%E8%BD%BD%E7%BB%84%E4%BB%B6)
  - [其他操作](#%E5%85%B6%E4%BB%96%E6%93%8D%E4%BD%9C)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 简介

此文档用于指导如何安装平台产品

两种安装方式

- [安装包部署](#%E5%AE%89%E8%A3%85%E5%8C%85%E9%83%A8%E7%BD%B2)
    - 安装包部署适用于已经发布离线包的版本
- [镜像部署](#%E9%95%9C%E5%83%8F%E9%83%A8%E7%BD%B2)
    - 镜像快速部署适用于内网安装

## 安装包部署

### 准备工作

- 使用完整的安装包部署，需要在安装 cargo 和 kernel 的机器上操作，参考 [Compass 容器云平台部署手册](https://docs.google.com/document/d/1BrLNUsbSpDM_v4Owv97fLCnG_ccIA2eULu8_Sx80Eyc/edit#heading=h.2yy1aubfzm7r) 

保存完整的安装包 `compass-component-v2.7.2-xx.tar.gz `

确保存放安装包的相对路径有 `.kubectl.kubeconfig` 和 `.install-env.sh` 文件

### 开始安装

安装时需要创建并修改 [config 文件](#%E5%88%9B%E5%BB%BA-config)

```bash
tar xvf compass-component-v2.7.2-xx.tar.gz 
cd compass-component-v2.7.2-xx/
cp config.sample config 
vi config
bash install.sh
```

### debug 模式修改 release

测试环境若要更新或者测试组件，可以通过安装包的 debug 模式来修改组件配置

1. 需要先登录到安装 compass-component 的 cargo 节点
    - 可以通过查看集群的 configMap 来查看此节点的ip
        ```bash
        $ kubectl get configMap platform-info -o yaml | grep cargo_registry_ip
          cargo_registry_ip: 192.168.133.9
        ```
    - 需要自行确认安装包的路径，可以咨询安装的人员或者 release-team 的伙伴

2. 登录安装节点，进入安装路径，使用脚本进入容器，修改对应组件的 chart yaml 并更新

- 容器内部，组件的 yaml 路径，compass 为 [addons](../addons)，oem 的产品路径为 `oem-addons`

```bash
ssh root@192.168.133.9
cd /${install-path}/compass-component-v2.7.2-xx/  # install-path 即是 cargo 节点安装包的安装路径，例如 /compass
bash install.sh debug
vim addons/console/console-web.yaml
python3 amctl.py update -p addons/console/console-web.yaml  # pod 更新需等待一分钟左右
```

## 镜像部署

### 镜像启动

使用版本发布之后的镜像或者自行构建镜像

如果是定时构建的镜像，每天的镜像都会更新

镜像命名规则为 `cargo-infra.caicloud.xyz/devops_release/release:auto-{date +%Y%m%d}`, 例如 auto-20190228

CentOs:

```bash
docker run --rm -it -v /etc/kubernetes/kubectl.kubeconfig:/root/.kube/config cargo-infra.caicloud.xyz/devops_release/release:$VERSION bash
```

Mac:

```bash
docker run --rm -it -v ~/.kube/config:/root/.kube/config cargo-infra.caicloud.xyz/devops_release/release:$VERSION bash
```

自行更改 $VERSION 为指定的版本

如需更新组件请参考 [升级组件](#%E5%8D%87%E7%BA%A7%E7%BB%84%E4%BB%B6)

### 创建 config

config 文件用于配置一些产品参数，如非必要，默认不修改

```
cp script/config.sample config
vi config
```

### 安装产品

如果存在 [产品安装描述文件](./configurable-product-installation.md)，可指定描述文件安装

例如通过 `compass.yaml` 描述文件来安装完整的产品组件

```bash
python3 amctl.py create -p compass.yaml
```

如果不存在描述文件，可分步安装

## 分步安装

### 依赖安装

```bash
python3 amctl.py init all
```

此处需要日志无报错，并等待 **pangolin** 组件正常启动，如下：

```txt
[root@c520v128]:~# kubectl get po | grep am
am-master-v3.0-64c5695894-hfhh7                                   1/1       Running             0          1d
am-minion-v3.0-6c5b5b4898-8667h                                   1/1       Running             0          1d
am-mysql-v2.0-7d546d6658-jv5r9                                    1/1       Running             0          1d
```

### 应用部署

```bash
python3 amctl.py install -p <addon-path>
```

addon-path 可以是 yaml 文件的路径，也可以是一个 folder 路径

- 如果是 yaml 路径，就会安装这个 yaml
- 如果是 folder 路径，会安装 folder 路径下所有的 yaml

example: 安装 console-web 路径下的 web 和 redis

```
python3 amctl.py install -p pangolin/addons/default/console-web
```

## 升级组件

修改 **addons** 文件夹下 **chart** 文件，修改完成后输入：

```bash
python3 amctl.py update -p <addon-path>
```

addon-path 可以是 yaml 文件的路径，也可以是一个 folder 路径

## 卸载组件

```bash
python3 amctl.py uninstall -p <addon-path>
```

## 其他操作

你可以通过以下命令获得更多操作指南

```bash
python3 amctl.py --help
```
