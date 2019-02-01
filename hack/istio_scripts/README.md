<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [简介](#%E7%AE%80%E4%BB%8B)
  - [istio_package.sh](#istio_packagesh)
  - [install.sh](#installsh)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## 简介

istio_scripts 目录包含 istio 打包和部署需要的脚本

### [istio_package.sh](./istio_package.sh)

此脚本用于打包 istio 插件包

传递参数：

- ISTIO_DIR:
    - 创建一个文件夹，例如 `istio_resources` ，用于保存 istio 的 `crds.yaml`，`istio.yaml` 以及安装的脚本 [install.sh](./install.sh)
- PLUGIN_YAML_PATH: 插件的 yaml 路径
- PACKAGE_VERSION: 插件包的版本

example:

```bash
bash istio_package.sh istio_resources release-plugins/istio-manager.yaml v1.0.0 
```

### [install.sh](./install.sh)

此脚本用于安装插件包，安装方法如下

下载安装包

```bash
$ cp compass-plugins-istio-v1.0.0.tar.gz /compass/compass-component-v2.7.3/
$ tar xvf compass-plugins-istio-v1.0.0.tar.gz && cd compass-plugins-istio-v1.0.0
$ bash install.sh
```
