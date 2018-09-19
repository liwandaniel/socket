<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [OEM Develop guidance](#oem-develop-guidance)
  - [OEM 分支创建](#oem-%E5%88%86%E6%94%AF%E5%88%9B%E5%BB%BA)
  - [OEM 定制](#oem-%E5%AE%9A%E5%88%B6)
    - [oem-addons](#oem-addons)
    - [oem-hotfixes](#oem-hotfixes)
    - [oem-images-lists](#oem-images-lists)
    - [oem-plugins](#oem-plugins)
    - [oem.yaml](#oemyaml)
  - [OEM 配置修改](#oem-%E9%85%8D%E7%BD%AE%E4%BF%AE%E6%94%B9)
  - [OEM Rebase](#oem-rebase)
  - [OEM 添加 pvc](#oem-%E6%B7%BB%E5%8A%A0-pvc)
  - [OEM 打包](#oem-%E6%89%93%E5%8C%85)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# OEM Develop guidance

## OEM 分支创建

请咨询 [platform-release 成员](https://github.com/orgs/caicloud/teams/platform-release/members)。

## OEM 定制

分支拉取后，在根目录下，按以下结构创建相应的文件夹以及文件：

```
.
├── oem-addons
├── oem-hotfixes
├── oem-images-lists
├── oem-plugins
└── oem.yaml(可选)
```

### oem-addons

该目录存放定制化的 [addons](../addons), 语法请参考 [Chart 模版配置规范定义](https://github.com/caicloud/charts#chart-%E6%A8%A1%E7%89%88%E9%85%8D%E7%BD%AE%E8%A7%84%E8%8C%83%E5%AE%9A%E4%B9%89v100)

同时，部署时会读取 [platform-info.yaml.j2](../platform-info.yaml.j2) 与 [platform-config.yaml.j2](../platform-config.yaml.j2) 生成 k8s configmap 并替换 addons 中格式为 `[[ variable name ]]` 的变量，具体实现可参考 [addons](../addons)。

### oem-hotfixes

该目录存放定制化的 [hotfixes](../release-hotfixes)，制作流程请参考 [产品组件热升级安装包](https://github.com/caicloud/compass-release#%E4%BA%A7%E5%93%81%E7%BB%84%E4%BB%B6%E7%83%AD%E5%8D%87%E7%BA%A7%E5%AE%89%E8%A3%85%E5%8C%85)

### oem-images-lists

该目录存放定制化组件的镜像列表 [images-lists](./images-lists)。

- 镜像存在于 [addons](../addons) 中的，可使用以下命令生成镜像列表：

```bash
    $ go get github.com/caicloud/pangolin/cmd/amctl
    $ amctl convert --addons-path=./oem-addons --export=./oem-images-lists/addons.list
```

- 其余镜像，请单独创建 list 文件记录

### oem-plugins

该目录存放定制化的 [release-plugins](../release-plugins)， 制作流程请参考 [产品插件安装包](https://github.com/caicloud/compass-release#%E4%BA%A7%E5%93%81%E6%8F%92%E4%BB%B6%E5%AE%89%E8%A3%85%E5%8C%85)

### oem.yaml

该文件描述 OEM 的功能模块，以及各模块中组件的相互依赖关系。在部署的时候，能够选择性地部署部分组件，禁用的组件不部署。

OEM owner 可以根据是否需要选择性地部署部分组件，来选择是否提供该描述文件。

文件制作请参考 [configurable-product-installation.md](./configurable-product-installation.md)

## OEM 配置修改

若要修改产品全局配置，参考 // TODO

## OEM Rebase

OEM 负责人根据 Compass 发布情况，择机 rebase。

## OEM 添加 pvc

若需要添加独立于 addons 之外的 pvc，请将 pvc 描述文件添加到 [../prerequisites/pvc/](../prerequisites/pvc), 部署时会自动安装上。

## OEM 打包

// TODO
