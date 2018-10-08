<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [OEM 打包流程](#oem-%E6%89%93%E5%8C%85%E6%B5%81%E7%A8%8B)
  - [打包流程](#%E6%89%93%E5%8C%85%E6%B5%81%E7%A8%8B)
    - [OEM chart 收集](#oem-chart-%E6%94%B6%E9%9B%86)
    - [更新组件 tag](#%E6%9B%B4%E6%96%B0%E7%BB%84%E4%BB%B6-tag)
    - [确认组件 tag](#%E7%A1%AE%E8%AE%A4%E7%BB%84%E4%BB%B6-tag)
    - [收集 chart](#%E6%94%B6%E9%9B%86-chart)
    - [生成镜像列表](#%E7%94%9F%E6%88%90%E9%95%9C%E5%83%8F%E5%88%97%E8%A1%A8)
    - [归档](#%E5%BD%92%E6%A1%A3)
    - [构建 release 镜像](#%E6%9E%84%E5%BB%BA-release-%E9%95%9C%E5%83%8F)
- [对内发布](#%E5%AF%B9%E5%86%85%E5%8F%91%E5%B8%83)
- [对外发布](#%E5%AF%B9%E5%A4%96%E5%8F%91%E5%B8%83)
  - [保存镜像包](#%E4%BF%9D%E5%AD%98%E9%95%9C%E5%83%8F%E5%8C%85)
    - [同步镜像](#%E5%90%8C%E6%AD%A5%E9%95%9C%E5%83%8F)
    - [打包镜像文件](#%E6%89%93%E5%8C%85%E9%95%9C%E5%83%8F%E6%96%87%E4%BB%B6)
  - [制作发布包](#%E5%88%B6%E4%BD%9C%E5%8F%91%E5%B8%83%E5%8C%85)
    - [包结构简析](#%E5%8C%85%E7%BB%93%E6%9E%84%E7%AE%80%E6%9E%90)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## OEM 打包流程

### 打包流程

从 github 获取 product-release 项目

- 切换到 oem 的分支

#### OEM chart 收集

OEM 有两种收集 chart 方式

1. 直接更新 chart 文件至 oem 分支下的 `oem-addons` 目录下
2. 将 chart 保存在每个组件 repo 根目录下的 `release` 目录下，通过 chart 收集工具统一收集到 `oem-addons` 目录下

- 第一种方式可以直接跳过 chart 收集的过程，[开始构建镜像](#%E6%9E%84%E5%BB%BA-release-%E9%95%9C%E5%83%8F)
- 第二种收集的方式继续按照流程

#### 更新组件 tag
- 在 github 创建 token，进入 product-release 根目录下创建 `token` 文件保存

读取 `charts_list.yaml`， 获取各个 repo 的最新 tag 并生成 `release_charts.yaml` 的描述文件用于收集 chart

```bash
make update-tag
```

#### 确认组件 tag

提 PR 至 product-release，由各个组件的负责人确认 `release_charts.yaml` 文件中的 tag

- 确保需要替换的镜像 tag 和 repo tag 一致
- 确保 tag 的 release 目录下有正确的 chart 文件

#### 收集 chart

确认 tag 之后，从每个 repo 收集 chart 文件，保存在 `oem-addons` 目录下

```bash
make collect-charts ADDONS_PATH=oem-addons
```

#### 生成镜像列表

使用 pangolin amctl 工具生成所有 chart 中包含的镜像列表

- `ADDONS_PATH` 可指定读取的文件路径，获取指定目录下所有 chart 文件中的镜像
- `TARGET_FILE` 可指定生成的文件名

```bash
make convert-images ADDONS_PATH=oem-addons TARGET_FILE=oem-images-lists/images_platform.list
```

```bash
$ cat images_platform.list
release/app-admin:v0.3.17
release/templates:v1.2.7
release/canary-nginx-proxy:v0.3.1
......
```

#### 归档

提 PR 至 product-release，将收集到的最新的 charts 和 image-lists 归档

#### 构建 release 镜像

基于 pangolin 工具镜像，构建 release 镜像

* RELEASE_VERSION 表示将要生成的 release 镜像的 tag
* 镜像全名为 `cargo-infra.caicloud.xyz/devops_release/release:v2.7.x-prexx`

```bash
make release-image RELEASE_VERSION=v2.7.x-prexx
```

在根目录下将 release 的镜像 save 成 `release.tar.gz`， 此包需要放入到完整的安装包 `image` 目录下

至此，release 的镜像已经构建完成

## 对内发布

对内发布，只需要将产品发布测试环境。参考 [镜像部署](./product-installation.md#%E9%95%9C%E5%83%8F%E9%83%A8%E7%BD%B2) 的部署步骤进行安装。

## 对外发布

对外发布，需要打包独立的安装包。

### 保存镜像包

#### 同步镜像

从流水线仓库同步到 [Release Harbor](https://harbor.caicloud.xyz/)， 再同步至打包用的镜像仓库（此镜像仓库需要自行搭建，并保证镜像仓库中没有其他的镜像）

使用 [pangolin 镜像同步脚本](https://github.com/caicloud/pangolin/blob/master/script/sync_images_scripts/sync.sh)

**将[镜像列表](#%E7%94%9F%E6%88%90%E9%95%9C%E5%83%8F%E5%88%97%E8%A1%A8)和脚本保存在同一目录下**

同步镜像之前需要先 `docker login`

- **同步至 Release Harbor**

```bash
bash sync.sh cargo-infra.caicloud.xyz harbor.caicloud.xyz
```

- **同步至干净的自有镜像仓库**

指定自有镜像仓库的域名，并确保 `etc/hosts` 的解析正确

```bash
bash sync.sh harbor.caicloud.xyz <cargo-prefix>
```

- 查看 `miss_image.txt` 和 `miss_push_image.txt` 确认是否有镜像同步失败

#### 打包镜像文件

若涉及部署`cargo`相关问题请咨询 @cd1989

cargo 中镜像文件保存在相对路径 `common/cargo-registry/` 目录下，需确认安装时的目录位置

```bash
$ cd common/cargo-registry/
$ tar -cvf pangolin-deploy-images.tar.gz docker/
```

由此，我们便得到一个镜像包。

### 制作发布包

#### 包结构简析

```bash
$ cd /compass && tar xvf compass-component-v2.7.x.tar.gz
$ tree compass-component-v2.7.x/
compass-component-v2.7.x/
|-- cadm
|-- config.sample
|-- install.sh
|-- image
|   `-- release.tar.gz
|-- pangolin-deploy-images.tar.gz
```

可以观察到包里一共五个文件：

- [cadm](https://github.com/caicloud/compass-admin/releases)
- [config.sample install.sh](https://github.com/caicloud/pangolin/tree/master/script)
- image 来自 [构建 release 镜像](#%E6%9E%84%E5%BB%BA-release-%E9%95%9C%E5%83%8F)
- `pangolin-deploy-images.tar.gz` 来自 [保存镜像包](#%E4%BF%9D%E5%AD%98%E9%95%9C%E5%83%8F%E5%8C%85)

安装包部署参考 [安装包部署](./product-installation.md#%E5%AE%89%E8%A3%85%E5%8C%85%E9%83%A8%E7%BD%B2)