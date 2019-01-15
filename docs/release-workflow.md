<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [release 发布流程](#release-%E5%8F%91%E5%B8%83%E6%B5%81%E7%A8%8B)
  - [准备工作](#%E5%87%86%E5%A4%87%E5%B7%A5%E4%BD%9C)
  - [自测日](#%E8%87%AA%E6%B5%8B%E6%97%A5)
    - [冒烟测试](#%E5%86%92%E7%83%9F%E6%B5%8B%E8%AF%95)
    - [增删改组件](#%E5%A2%9E%E5%88%A0%E6%94%B9%E7%BB%84%E4%BB%B6)
    - [更新 repo tag](#%E6%9B%B4%E6%96%B0-repo-tag)
    - [添加 k8s resources](#%E6%B7%BB%E5%8A%A0-k8s-resources)
    - [推送镜像](#%E6%8E%A8%E9%80%81%E9%95%9C%E5%83%8F)
  - [发布日](#%E5%8F%91%E5%B8%83%E6%97%A5)
    - [打包流程](#%E6%89%93%E5%8C%85%E6%B5%81%E7%A8%8B)
    - [测试发布](#%E6%B5%8B%E8%AF%95%E5%8F%91%E5%B8%83)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# release 发布流程

## 准备工作

**以下事项由 release team 负责，自测日前一天完成**：

* 跟 PM 确认发布时间
* 由 QA 自行准备冒烟环境， release team 提供协助
 
## 自测日

**以下事项由研发负责，自测日下班前完成**：

### 冒烟测试

下午5点前完成，5点研发 TL 开会 Review 结果。[测试用例](https://docs.google.com/spreadsheets/d/1OVmGzSTieJuZA0q01npleWbXe2v8hSUgakEzWxN9Oec/edit#gid=2033378945)

### 增删改组件

所有的增删改组件的操作，都需要同步到 release-team

**需要以下操作:**

1. 在 [charts_list.yaml](../charts_list.yaml) 文件中添加新的 repo 配置
    - 这个文件用于统一收集每个组件各自维护的 release chart yaml
    - 添加或修改 repo 的名称 `repositoryFullName`
    - chart yaml 保存在 repo 的路径 `resourcePaths`，路径统一为 repo 根目录的 release 目录下
    - chart yaml 在项目中保存的路径 `targetPath`，推荐命名为组件的分组名称的文件夹，例如 `console-web-web` 和 `console-web-redis`，统一保存在分组 `console` 目录下
        ```yaml
          - repositoryFullName: caicloud/console-web
            resourcePaths:
              - release/console-web.yaml
              - release/console-web-redis.yaml
              - release/web-gateway-proxy.yaml
            targetPath: console
        ```
2. 在 [compass.yaml](../compass.yaml) 以及 [mini-compass.yaml](../mini-compass.yaml) 中添加部署配置
    - 这两个文件是用于部署的描述文件，包括完整的 compass 和 mini-compass，控制着安装部署哪些组件
    - 关于这两个描述文件，可以参考 [产品模块描述文件](./configurable-product-installation.md)
    - oem 产品则修改 oem 分支根目录下的 oem.yaml

### 更新 repo tag

研发代码 merge 之后，需要打新的 tag 触发流水线构建镜像

打包工具提供根据 repo tag 替换镜像 tag，只需在 yaml 中加上环境变量 `[[ imageTagFromGitTag ]]` 即可替换

```
image: '[[ registry_release ]]/hodor:[[ imageTagFromGitTag ]]'
```

也可使用其他 repo 的 tag 替换镜像 tag

在 charts_list.yaml 中添加需要用来替换的 repo

```yaml
- repositoryFullName: caicloud/charts
```

同时在 release 的 yaml 中加上环境变量 `[[ TagOfRepo(charts) ]]` 即可替换

- 括号中填写 repo 的名字， `[[ TagOfRepo(charts) ]]` 表示使用 `caicloud/charts` 的 tag 来替换

```
image: '[[ registry_release ]]/templates:[[ TagOfRepo(charts) ]]'
```

不经常更新的组件，可以在 yaml 中指定镜像版本，并更新至最新的 tag 下

发布之前需要确保镜像已经推送到流水线仓库，如需替换的镜像 tag 需要和 repo tag 保持一致

### 添加 k8s resources

支持使用 `kubectl apply` 部署 k8s 原生的 yaml，发布流程如下

在 product-release 的 [prerequisites](../prerequisites) 目录下创建 `k8s_resources` 目录，用于保存 yaml，部署 compass 的过程中会自动将这些资源部署到集群

- oem 的资源需要保存在目录 `oem_k8s_resources` 下，同 compass 产品线区分开

支持使用集群变量替换的方式，用法和 chart yaml 中的用法一致

```yaml
image: '[[ registry_release ]]/am_minion:v0.0.8'
```

### 推送镜像

- 镜像统一由流水线构建并推送 `cargo-infra.caicloud.xyz`
- 产品定制镜像，推送 `devops_release` 项目
- 上游镜像，推送 `library` 项目

## 发布日

**以下事项由 release team 负责，发布日晚七点前完成，否则算发布失败。若失败，请总结（[demo](https://github.com/caicloud/platform/issues/683)）**：

### 打包流程

参考 [产品打包发布流程](./package.md)

### 测试发布

根据测试用例，自测部署包，测试完成后上传 OSS

按照 [Compass 容器云平台部署手册](https://docs.google.com/document/d/1BrLNUsbSpDM_v4Owv97fLCnG_ccIA2eULu8_Sx80Eyc/edit#heading=h.2yy1aubfzm7r) 进行安装
