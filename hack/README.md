<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [简介](#%E7%AE%80%E4%BB%8B)
  - [sync.sh](#syncsh)
  - [install.sh](#installsh)
    - [install mode](#install-mode)
    - [debug mode](#debug-mode)
    - [hotfix mode](#hotfix-mode)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## 简介

script 目录包含打包和部署需要的脚本

### [sync.sh](./sync_images_scripts/sync.sh)

此脚本用于打包时同步镜像，参考 [打包同步镜像流程](https://github.com/caicloud/product-release/blob/master/docs/package.md#%E5%90%8C%E6%AD%A5%E9%95%9C%E5%83%8F)

example:

```bash
bash sync.sh cargo-infra.caicloud.xyz harbor.caicloud.xyz
```

### [install.sh](./install.sh)

此脚本用于安装产品，安装包可参考 [打包发布流程](https://github.com/caicloud/product-release/blob/master/docs/package.md)

```bash
$ tree compass-component-v2.7.x/
compass-component-v2.7.x/
├── cadm
├── config.sample
├── install.sh
├── image
│   └── release.tar.gz
└── pangolin-deploy-images.tar.gz
```

脚本有三种用法：

#### install mode

用于安装产品

```bash
bash install.sh
```

oem 产品的安装需要更改配置文件 [config.sample](./config.sample)

```bash
cp config.sample config && vim config
```

#### debug mode

进入 release 镜像，便于手动更新 chart

```bash
bash install.sh debug
```

#### hotfix mode

用于安装 hotfix 补丁包

在脚本同级目录创建 `hotfixes` 目录，目录下存放 hotfix 的补丁包

```bash
bash install.sh hotfix
```
