<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [产品模块描述文件](#%E4%BA%A7%E5%93%81%E6%A8%A1%E5%9D%97%E6%8F%8F%E8%BF%B0%E6%96%87%E4%BB%B6)
  - [描述](#%E6%8F%8F%E8%BF%B0)
  - [例子](#%E4%BE%8B%E5%AD%90)
    - [更多例子](#%E6%9B%B4%E5%A4%9A%E4%BE%8B%E5%AD%90)
  - [字段说明](#%E5%AD%97%E6%AE%B5%E8%AF%B4%E6%98%8E)
  - [局限性](#%E5%B1%80%E9%99%90%E6%80%A7)
  - [部署安装](#%E9%83%A8%E7%BD%B2%E5%AE%89%E8%A3%85)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 产品模块描述文件

## 描述

通过 yaml 文件描述产品的功能模块，以及各模块中组件的相互依赖关系。在部署的时候，能够选择性地部署部分组件，禁用的组件不部署。

该描述文件遵循如下原则：

- 组件按照功能模块划分
- 只描述依赖间的一层依赖关系
- 功能模块可以选择是否开启，同时组件也可以选择是否部署
- 模块在禁用的情况下，其被依赖的组件，还是要部署

## 例子

```yaml
---
metadata:
 name: mini compass
 version: 2.7.1
 description: mini compass deployment config
spec:
 systemAddons:
 - name: tenant-admin
   description: Manage tenants
 - name: cluster-admin
   description: Manage clusters
 - name: hodor
   description: API Gateway
 - name: license
   description: Product license
 - name: infra-mongo
   description: MongoDB Cluster
 modules:
 - name: devops
   description: CI/CD
   required: false
   addons:
   - name: devops-admin
     description: xxxx
     deps:
     - storage-admin
   - name: cyclone
     description: xxxx
 - name: cargo
   description: 镜像仓库
   required: true
   addons:
   - name: cargo-admin
     description: xxxx
 - name: storage
   description: xxxx
   required: true
   addons:
   - name: storage-admin
     description: xxxx
   - name: storage-admin-controller
     description: xxxx
   - name: storage-admission
     description: xxxx
   - name: storage-controller
     description: xxxx
   - name: storage-provisioner
     description: xxxx
 extraAddons:
 - name: logging-admin
   description: Provide log for Clever
```

### 更多例子

- [完整 compass](../compass.yaml)
- [mini compass](../mini-compass.yaml)

## 字段说明

- systemAddons：平台在系统级别需要的组件，不管是否为 mini 模式，都需要安装
- modules：平台的功能模块列表
- Addons：模块中的组件列表
- required：是否需要部署改模块
- description：模块或者 addon 的描述信息
- deps：组件依赖的其他组件，如果依赖的组件已经在 system 中，就不用再描述
- addon name：为 release name，组件的唯一标示，不能有重复
- extraAddons：需要额外部署的 addon
- name：addon 名称
- description：模块或者 addon 的描述信息

## 局限性

- Yaml 需要准确描述组件间的依赖关系
- 只能在部署的时候进行选择，不支持动态开启和关闭功能模块

## 部署安装

参考 [product-installation.md](./product-installation.md)
