<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Package Workflow](#package-workflow)
  - [Create your clone](#create-your-clone)
  - [构建 release 镜像](#%E6%9E%84%E5%BB%BA-release-%E9%95%9C%E5%83%8F)
    - [标准产品构建镜像](#%E6%A0%87%E5%87%86%E4%BA%A7%E5%93%81%E6%9E%84%E5%BB%BA%E9%95%9C%E5%83%8F)
    - [oem 构建镜像](#oem-%E6%9E%84%E5%BB%BA%E9%95%9C%E5%83%8F)
    - [保存镜像](#%E4%BF%9D%E5%AD%98%E9%95%9C%E5%83%8F)
  - [对内发布](#%E5%AF%B9%E5%86%85%E5%8F%91%E5%B8%83)
  - [对外发布](#%E5%AF%B9%E5%A4%96%E5%8F%91%E5%B8%83)
    - [制作产品镜像包](#%E5%88%B6%E4%BD%9C%E4%BA%A7%E5%93%81%E9%95%9C%E5%83%8F%E5%8C%85)
      - [同步镜像](#%E5%90%8C%E6%AD%A5%E9%95%9C%E5%83%8F)
      - [打包镜像文件](#%E6%89%93%E5%8C%85%E9%95%9C%E5%83%8F%E6%96%87%E4%BB%B6)
    - [制作发布包](#%E5%88%B6%E4%BD%9C%E5%8F%91%E5%B8%83%E5%8C%85)
    - [安装发布包](#%E5%AE%89%E8%A3%85%E5%8F%91%E5%B8%83%E5%8C%85)
    - [上传发布包](#%E4%B8%8A%E4%BC%A0%E5%8F%91%E5%B8%83%E5%8C%85)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Package Workflow

该文档针对 OEM 流程，也适用于 Compass 产品发布。

## Create your clone

执行以下命令：

```bash
git clone https://github.com/caicloud/product-release.git
# or: git clone git@github.com:caicloud/product-release.git
```

## 构建 release 镜像

切换到 release tag 并执行：

```bash
cd product-release
git checkout $RELEASE_TAG
git describe --tags --always --dirty
```

使用最新的 release tag 替换 $RELEASE_TAG 并确保 `git describe --tags --always --dirty` 的输出与 $RELEASE_TAG 一致。

### 标准产品构建镜像

执行以下命令：

```bash
make release-image RELEASE_VERSION=v2.7.3
```

### oem 构建镜像

针对 oem 产品，类似于 clever 的增量包，需要保留 compass 原有的版本号，同时又增加 oem 产品的版本号

- 需要在 [Makefile](../Makefile) 中注明基于哪个 compass 版本
    - 如果作为基础的 compass 版本发生变化，需要跟随修改 compass 版本信息
    ```
    BASE_RELEASE_VERSION       ?= v2.7.2
    BASE_RELEASE_TIME          ?= 2018-10-26 18:00
    ```

- 在 oem 分支的 [platform-info](../platform-info.yaml.j2) 中添加变量
    ```
    oem_product_release_version: G_OEM_RELEASE_VERSION
    oem_product_release_time: G_OEM_RELEASE_TIME
    ```

构建镜像需要添加执行参数 `OEM_PRODUCT_NAME` 即 oem 产品的名称

```bash
make release-image RELEASE_VERSION=clever-v1.3.0 OEM_PRODUCT_NAME=clever
```

最终会在 [platform-info](../platform-info.yaml.j2) 中添加 compass 的版本号和 oem 产品的版本号

```
  platform_release_version: "v2.7.2"
  platform_release_time: "2018-10-26 18:00"
  clever_release_version: "clever-v1.3.0"
  clever_release_time: "2018-12-19 10:00"
```

### 保存镜像

上述命令将会：

- 生成并推送 `cargo.caicloudprivatetest.com/caicloud/release:$RELEASE_TAG`
- 在根目录下将 release 镜像通过 `docker save` 至 `release.tar.gz`， 此包后面会用到。

## 对内发布

对内发布，只需要将产品发布测试环境。参考 [镜像部署](./product-installation.md#%E9%95%9C%E5%83%8F%E9%83%A8%E7%BD%B2) 的部署步骤进行安装。

## 对外发布

对外发布，需要打包独立的安装包。

### 制作产品镜像包

#### 同步镜像

Step 1， 执行以下命令：

```bash
docker login harbor.caicloud.xyz -u admin -p $HARBOR_PASSWORD
docker login cargo-infra.caicloud.xyz -u admin -p $CARGO_PASSWORD
./hack/sync_images_scripts/sync.sh cargo-infra.caicloud.xyz harbor.caicloud.xyz ./oem-images-lists
```

修改 `$HARBOR_PASSWORD` 和 `$CARGO_PASSWORD` 为对应的值。

上述命令将从 cargo-infra.caicloud.xyz 同步列表镜像到 harbor.caicloud.xyz

Step 2，再起一个新搭建的 Cargo 镜像仓库，搭建过程参考 [Cargo Readme](https://github.com/caicloud/cargo/blob/master/README.md)

执行以下命令：

```bash
sudo echo "$CARGO_IP cargo.caicloudprivatetest.com" >> /etc/hosts
docker login harbor.caicloud.xyz -u admin -p $HARBOR_PASSWORD
docker login cargo.caicloudprivatetest.com -u admin -p $CARGO_PASSWORD
./hack/sync_images_scripts/sync.sh harbor.caicloud.xyz cargo.caicloudprivatetest.com ./oem-images-lists
```

修改 `$CARGO_IP`、 `$HARBOR_PASSWORD` 和 `$CARGO_PASSWORD` 为对应的值。

上述命令将从 harbor.caicloud.xyz 同步列表镜像到 cargo.caicloudprivatetest.com。

执行结束后，可以通过以下命令确认是否有镜像同步失败。

```bash
cat miss_image.txt
cat miss_push_image.txt
```

#### 打包镜像文件

执行以下命令：

```bash
# 进入 cargo 所在机器 cargo 安装目录，一般是 /compass
./cargo-ansible/cargo/templates/scripts/stop.sh
cd common/cargo-registry/
tar -cvf pangolin-deploy-images.tar.gz docker/
```

cargo 中镜像文件默认保存在相对路径 `common/cargo-registry/` 下

上述命令将产生一个产品镜像包 pangolin-deploy-images.tar.gz，后续步骤会用到。

### 制作发布包

包结构简析：

```bash
$ cd /compass && tar xvf compass-component-v2.7.x.tar.gz
$ tree compass-component-v2.7.x/
compass-component-v2.7.x/
├── cadm
├── config.sample
├── install.sh
├── image
│   └── release.tar.gz
└── pangolin-deploy-images.tar.gz
```

可以观察到包里一共五个文件：

- [cadm](https://github.com/caicloud/compass-admin/releases)
- [config.sample install.sh](../hack/)
- image 下文件来自[构建 release 镜像](#%E6%9E%84%E5%BB%BA-release-%E9%95%9C%E5%83%8F)
- `pangolin-deploy-images.tar.gz` 来自[制作产品镜像包](#%E5%88%B6%E4%BD%9C%E4%BA%A7%E5%93%81%E9%95%9C%E5%83%8F%E5%8C%85)

执行以下命令：

```bash
tar cvf compass-component-v2.7.x.tar.gz ./compass-component-v2.7.x
```

### 安装发布包

安装包部署参考 [安装包部署](./product-installation.md#%E5%AE%89%E8%A3%85%E5%8C%85%E9%83%A8%E7%BD%B2)。

### 上传发布包

参考 [OSS 配置文档](https://docs.google.com/document/d/1n-zJxQ-v--6ohGyNotkGpkBiVfhyOqfuW-fUeIOlwzE/edit)
