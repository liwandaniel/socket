<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [产品自动化打包发布](#%E4%BA%A7%E5%93%81%E8%87%AA%E5%8A%A8%E5%8C%96%E6%89%93%E5%8C%85%E5%8F%91%E5%B8%83)
  - [准备发布环境](#%E5%87%86%E5%A4%87%E5%8F%91%E5%B8%83%E7%8E%AF%E5%A2%83)
    - [服务器配置](#%E6%9C%8D%E5%8A%A1%E5%99%A8%E9%85%8D%E7%BD%AE)
      - [部署 cargo](#%E9%83%A8%E7%BD%B2-cargo)
      - [制作 ansible 镜像](#%E5%88%B6%E4%BD%9C-ansible-%E9%95%9C%E5%83%8F)
      - [配置 cargo 节点的 oss](#%E9%85%8D%E7%BD%AE-cargo-%E8%8A%82%E7%82%B9%E7%9A%84-oss)
      - [准备 cadm 文件](#%E5%87%86%E5%A4%87-cadm-%E6%96%87%E4%BB%B6)
    - [Jenkins 配置](#jenkins-%E9%85%8D%E7%BD%AE)
      - [自动化所需参数](#%E8%87%AA%E5%8A%A8%E5%8C%96%E6%89%80%E9%9C%80%E5%8F%82%E6%95%B0)
  - [compass 发布](#compass-%E5%8F%91%E5%B8%83)
    - [自动化发布](#%E8%87%AA%E5%8A%A8%E5%8C%96%E5%8F%91%E5%B8%83)
      - [Jenkins 参数化构建](#jenkins-%E5%8F%82%E6%95%B0%E5%8C%96%E6%9E%84%E5%BB%BA)
      - [构建流程](#%E6%9E%84%E5%BB%BA%E6%B5%81%E7%A8%8B)
    - [手动打包](#%E6%89%8B%E5%8A%A8%E6%89%93%E5%8C%85)
      - [脚本说明](#%E8%84%9A%E6%9C%AC%E8%AF%B4%E6%98%8E)
      - [同步镜像](#%E5%90%8C%E6%AD%A5%E9%95%9C%E5%83%8F)
      - [判断镜像是否丢失](#%E5%88%A4%E6%96%AD%E9%95%9C%E5%83%8F%E6%98%AF%E5%90%A6%E4%B8%A2%E5%A4%B1)
      - [打包](#%E6%89%93%E5%8C%85)
      - [上传](#%E4%B8%8A%E4%BC%A0)
  - [hotfix 发布](#hotfix-%E5%8F%91%E5%B8%83)
    - [hotfix 自动化发布](#hotfix-%E8%87%AA%E5%8A%A8%E5%8C%96%E5%8F%91%E5%B8%83)
      - [Jenkins 参数化构建](#jenkins-%E5%8F%82%E6%95%B0%E5%8C%96%E6%9E%84%E5%BB%BA-1)
      - [构建流程](#%E6%9E%84%E5%BB%BA%E6%B5%81%E7%A8%8B-1)
    - [hotfix 手动打包](#hotfix-%E6%89%8B%E5%8A%A8%E6%89%93%E5%8C%85)
      - [脚本说明](#%E8%84%9A%E6%9C%AC%E8%AF%B4%E6%98%8E-1)
      - [env.sh](#envsh)
      - [打包](#%E6%89%93%E5%8C%85-1)
      - [上传](#%E4%B8%8A%E4%BC%A0-1)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 产品自动化打包发布

## 准备发布环境

### 服务器配置

#### 部署 cargo 

- 准备一台 cargo 的机器，部署一个 cargo 的服务做同步镜像和打包使用

部署方式参考 [部署文档](https://docs.google.com/document/d/1hnEdqaDRbHsfLYf89kv_SEv0-RXCes4BF6oZU4ObeMY/edit#heading=h.1ukox7hn0kj1)

#### 制作 ansible 镜像

此步骤只在更新镜像时使用，通常情况可直接跳过，保持默认镜像版本即可

```bash
git clone https://github.com/caicloud/product-release.git
# or: git clone git@github.com:caicloud/product-release.git
cd product-release
```

构建镜像

```bash
make build-image JENKINS_VERSION=v0.0.x
```

如果需要修改 ansible 镜像，需要修改 Jenkinsfile 中 ansible 的镜像版本，如非必要，则不修改

```bash
  - name: ansible
    image: "${DOCKER_REGISTRY_PREFIX}/golang-jenkins:v0.0.x"
    imagePullPolicy: Always
    tty: true
```

#### 配置 cargo 节点的 oss

参考 [oss 配置文档](https://forum.caicloud.xyz/t/topic/100)

- 将 ossutil 执行文件和配置文件放置在 `/root` 目录下

#### 准备 cadm 文件

在 cargo 节点的 `/root` 路径下放置指定的 cadm 文件

自动打包过程中会判断文件是否存在，如果存在，则会直接使用该路径下的 cadm，如果不存在，则会拉取 `compass-admin` 的代码并构建 cadm 文件

### Jenkins 配置

此处不做细节的解释，需要注意以下几点：
1. github CLA 的配置
2. 集群配置
3. cargo 机器的 ssh 登录 credential 配置（ 注意是 ssh 登录 ）
4. 用于同步的 cargo 仓库的登录 credential 配置（ 这里是 `docker login` 的登录配置）

#### 自动化所需参数

- `sha1`: checkout scm 的分支名，默认为 `*/master`，例如 clever 分支，则填写 `oem-clever` 完整的分支名
- `base_branch`: 用于额外拉取代码以及更新代码使用，填写完整的分支名，例如 `oem-clever`，和 `sha1` 保持一致，默认为 master
- `git_email`: CLA 的配置
- `github_credential_id`: github 账号和密码配置的 credential
- `docker_registry`: Jenkins 运行 pod 拉取镜像的仓库域名
- `docker_project`: Jenkins 运行 pod 拉取镜像的仓库项目名
- `docker_credential_id`: docker 登录的配置，默认为配置名为 `cargo-infra.caicloud.xyz` 的凭据
- `release_cargo_login`: cargo 节点的 ip 和密码配置，用于 ansible 远程操作，默认为配置名为 `release_cargo_login` 的凭据
- `source_registry`: 研发发布之前通过流水线推送镜像的仓库域名，发布的时候会从这个 cargo 获取镜像，无 cargo 迁移之类的操作，不用修改，默认为 `cargo-infra.caicloud.xyz/`
- `source_project`: 拉取 hotfix 镜像，source_registry 的 project 名字，默认为 `devops_release`
- `source_registry_credential_id`: source_registry 仓库的登录配置
- `target_registry`: 所有的发布镜像统一同步保存的仓库域名，若无特殊变动，默认为 `harbor.caicloud.xyz`
- `target_project`: 所有的发布镜像统一同步保存的仓库项目地址，同时也是 hotfix `docker save` 镜像的前缀 project，默认为 `release`
- `target_registry_credential_id`: target_registry 仓库的登录配置
- `release_registry`: 打包发布的镜像仓库域名，即上面服务器部署用于发布的仓库
- `release_registry_credential_id`: release_registry 仓库的登录配置
- `collect`: 选择是否进行收集 charts 的操作，默认为 false
- `release`: 选择是否进行构建镜像的操作，默认为 false
- `oem`: 选择打包 release 或者 hotfix 是否针对 oem 分支，oem 和 标准产品的保存路径不一样，需要区别开，默认为 false
- `increment_release`: 针对 oem 产品，存在两种打包方式，此选项 false 可以选择打包成为一个完整的 oem compass 版本，true 为打包成为增量包，增量包即安装完标准 compass 之后再次安装的包
- `release_version`: 产品发布版本号, 例如 `v2.7.3-rc01`
- `product_name`: 填写 oem 打包对应的产品线名称，用于打包的命名，例如 clever，命名规则类似于 `clever-component-xxx`，默认为 compass
- `package`: 选择是否打包上传，默认为 false
- `cargo_dir`: 配置 cargo 部署的路径，根据实际发布环境 cargo 的路径决定
- `sync_dir`: 配置同步镜像的路径, [镜像列表](../images-lists)和[镜像同步脚本](../hack/sync_images_scripts/sync.sh)保存的路径，如非必要，保持默认即可
- `release_oss_path`: 上传 oss 路径，例如 `compass-v2.7.3-rc/01` 
    - 最终拼接成完整的路径为 `oss://infra-release/platform/compass-v2.7.3-rc/01/compass-component-v2.7.3-rc01.tzr.gz`
- `hotfix`: 选择是否制作 hotfix，默认为 false
- `hotfix_dir`: 存放 hotfix 脚本和 hotfix yaml 的路径，如非必要保持默认即可
- `hotfix_yaml_path`: 指定 `product-release` repo 中 [release-hotfixes](../release-hotfixes) 目录下的 hotfix 路径，例如 `2.7.1/20180907`
- `hotfix_oss_path`: 上传 oss 路径，例如 `compass-v2.7.3` 
    - 最终拼接成完整的路径为 `oss://infra-release/platform/compass-v2.7.3/hotfixes/2018xxxx/...`    

## compass 发布

### 自动化发布

#### Jenkins 参数化构建

选择配置好的 Jenkins 流水线，点击 `Build with Parameters` 参数化构建

每次构建必须配置项：

- `sha1`: checkout scm 的分支名，默认为 `*/master`，例如 clever 分支，则填写 `oem-clever` 完整的分支名
- `base_branch`: 用于额外拉取代码以及更新代码使用，填写完整的分支名，例如 `oem-clever`，和 `sha1` 保持一致，默认为 master
- `collect`: 选择为 true
- `release`: 选择为 true
- `oem`: 按照实际情况，如果是 oem 的打包或者 oem 的 hotfix，则选择为 true
- `increment_release`: 针对 oem 打包，如果是为增量包，则选择为 true
- `release_version`: 产品发布版本号, 例如 `v2.7.3-rc01`
- `product_name`: 填写 oem 打包对应的产品线名称，用于打包的命名，例如 clever，命名规则类似于 `clever-component-xxx`，默认为 compass
- `package`: 如果需要打包上传 oss，则选择为 true
- `release_oss_path`: 上传 oss 路径，例如 `compass-v2.7.3-rc/01` 
    - 最终拼接成完整的路径为 `oss://infra-release/platform/compass-v2.7.3-rc/01/compass-component-v2.7.3-rc01.tzr.gz`
    
其他参数如非必要，保持默认即可


#### 构建流程

![image](https://user-images.githubusercontent.com/25719123/48244967-8ddf2580-e423-11e8-8893-45eb0ab68596.png)

1. Checkout: 拉取 product-release 代码
2. Lint Charts:
    - collectTags 获取各个组件 repo 最新的 tag, 并提交 PR 至 product-release 由各个组件负责人确认
    - collectCharts 收集各个组件的 release chart 并提交 PR 归档至 product-release
        
    **此步骤会暂停，等待 release 小组确认 PR merged 再手动触发 Proceed 至下一步**
    
    ![image](https://user-images.githubusercontent.com/25719123/48041971-8406b980-e1ba-11e8-9c31-55c434212904.png)

3. Make Release: 构建 release 镜像并 `docker save` 为一个 tar.gz 文件供最终打包发布使用
4. Sync images: 使用 ansible 将 images-lists 和 同步脚本 cp 至 cargo 节点，并使用脚本同步镜像至 cargo
5. Packaging: 将 `cadm， 部署脚本，release 镜像包，config.sample 文件，打包好的镜像包` 一起打包成为最终的发布包
6. Cadm: 判断 cargo 节点 `/root` 目录下是否存在 cadm 文件，有则直接 copy， 没有则获取 compass-admin master 分支代码，并构建 cadm 二进制文件
7. Upload:
    - 此步骤会暂停，等待 release 小组确认安装包是否没问题再进行上传

最后需要确认 oss 上传是否无误

至此，自动化发布的流程就完成了

### 手动打包

非自动化特殊情况下，可以运行打包脚本来协助完成打包

#### 脚本说明

具体可查看脚本 [package.sh](../hack/auto_package/package.sh)

参数说明：

1. INPUT: 可选参数为 `sync, judge, package, upload`, 传递不同的参数以执行不同的逻辑
    - sync: 同步镜像使用
    - judge: 判断是否有镜像同步失败
    - package: 打包
    - upload: 上传oss
2. RELEASE_VERSION: 发布版本，例如 `v2.7.3-rc01`
3. CARGO_DIR: cargo 部署的路径，即该目录下有保存镜像文件的 `./common/cargo-registry` 目录，例如 `/var/lib/kubelet/compass`
4. PRODUCT_NAME: 填写打包对应的产品线名称，用于打包的命名，例如 clever，命名规则类似于 `clever-component-xxx`，默认为 compass
5. SYNC_DIR: [镜像列表](../images-lists)和[镜像同步脚本](../hack/sync_images_scripts/sync.sh)保存的路径，例如 `/root/sync-scripts`
6. OSS_PATH: oss 上传的路径，例如 `compass-v2.7.3-rc/01`，最终上传路径为 `oss://infra-release/platform/compass-v2.7.3-rc/01/compass-component-v2.7.3-rc01.tar.gz`

#### 同步镜像

首先确保[镜像列表](../images-lists)和[镜像同步脚本](../hack/sync_images_scripts/sync.sh)在指定的路径

例如保存在 `/root/sync-scripts`

先要修改同步镜像需要的三个镜像仓库域名

- source_registry: 研发通过流水线推送镜像的仓库来源
- target_registry: 通常为 `harbor.caicloud.xyz`，发布出去的镜像需要保存在标准仓库
- release_registry: 打包使用的镜像仓库

同时需要注意修改 `/etc/hosts`，并在同步镜像前 `docker login -u admin -p PASSWORD CARGO-PREFIX`

```bash
sed -i 's/source_registry/${SOURCE_REGISTRY}/g' /root/package.sh
sed -i 's/target_registry/${TARGET_REGISTRY}/g' /root/package.sh
sed -i 's/release_registry/${RELEASE_REGISTRY}/g' /root/package.sh
$ bash package.sh sync v2.7.3-rc01 /var/lib/kubelet/compass compass /root/sync-scripts
```

此处会清空 cargo 中的镜像，使得 cargo 成为一个干净的仓库


#### 判断镜像是否丢失

```bash
$ bash package.sh judge v2.7.3-rc01 /var/lib/kubelet/compass compass /root/sync-scripts
no missed image, will proceed
```

如果有镜像缺失，会输出如下，手动去镜像列表的目录下查看 `miss_image.txt`，确认哪些镜像缺失

```bash
got missed images, exit
```

#### 打包

```bash
bash package.sh package v2.7.3-rc01 /var/lib/kubelet/compass compass
```

然后手动将其余打包需要的介质放入到打包目录下 `/var/lib/kubelet/compass/compass-component-v2.7.3-rc01`

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

此步骤不会将文件打包成 tar.gz 的安装包，由于安装包还需由 release 小组确认，待确认之后，在上传的步骤会自动打包

#### 上传

```bash
bash /root/package.sh upload v2.7.3-rc01 /var/lib/kubelet/compass /root/sync-scripts compass compass-v2.7.3-rc/01
```

待脚本结束，需去 oss 上确认是否上传成功

## hotfix 发布

### hotfix 自动化发布

#### Jenkins 参数化构建

选择配置好的 Jenkins 流水线，点击 `Build with Parameters` 参数化构建

每次构建必须配置项：

- `sha1`: checkout scm 的分支名，默认为 `*/master`，例如 clever 分支，则填写 `oem-clever` 完整的分支名
- `base_branch`: 用于额外拉取代码以及更新代码使用，填写完整的分支名，例如 `oem-clever`，和 `sha1` 保持一致，默认为 master
- `product_name`: 填写 oem 打包对应的产品线名称，用于打包的命名，例如 clever，命名规则类似于 `clever-component-xxx`，默认为 compass
- `hotfix`: 当要发布 hotfix 的时候选择为 true，`release` 和 `package` 都保持 false
- `hotfix_yaml_path`: 指定 `product-release` repo 中 [release-hotfixes](../release-hotfixes) 目录下的 hotfix 路径，例如 `2.7.1/20180907`
- `hotfix_oss_path`: 上传 oss 路径，例如 `compass-v2.7.3` 
    - 最终拼接成完整的路径为 `oss://infra-release/platform/compass-v2.7.3/hotfixes/2018xxxx/...`
    
其他参数如非必要，保持默认即可

#### 构建流程

![image](https://user-images.githubusercontent.com/25719123/48465098-aaf96700-e81c-11e8-8713-bd44685f996a.png)

1. Checkout: 拉取 product-release 代码
2. Lint Charts: 检查 charts 的规范
3. Make Hotfix: 制作 hotfix 的安装包
4. Upload: 上传至 oss
    - 这一步需要手动确认，待 release 小组确认 hotfix 安装包没问题之后再进行上传

最后需要确认 oss 上传是否无误

至此，hotfix 自动化发布的流程就完成了

### hotfix 手动打包

非自动化特殊情况下，可以运行 hotfix 脚本来协助完成打包

#### 脚本说明

具体可查看脚本 [hotfix.sh](../hack/auto_hotfix/hotfix.sh)

参数说明：

1. CHOICE: 可选参数为 `hotfix, upload`, 传递不同的参数以执行不同的逻辑
    - hotfix: 打包 hotfix 安装包
    - upload: 上传oss
2. UPLOAD_OSS_PATH: 上传 oss 的路径
3. HOTFIX_YAML_PATH: 读取 hotfix charts 的路径

#### env.sh

需要放在 `hotfix.sh` 脚本的同级目录下，用于配置 hotfix 打包时 pull 和 push 镜像的域名和项目名

修改配置信息

- SOURCE_REGISTRY: 镜像来源仓库，通常为流水线构建之后推送的仓库 `cargo-infra.caicloud.xyz`

- TARGET_REGISTRY: 镜像发布仓库，通常为 `harbor.caicloud.xyz`

```bash
sed -i 's/source_registry/${SOURCE_REGISTRY}/g;s/source_project/${SOURCE_PROJECT}/g' env.sh
sed -i 's/target_registry/${TARGET_REGISTRY}/g;s/target_project/${TARGET_PROJECT}/g' env.sh
```

#### 打包

将 product-release repo 中的 [release-hotfixes](../release-hotfixes) 目录保存下来，例如保存在 `/root/release-hotfixes`

如果是 oem 的 hotfix， 需要保存指定分支下的 `oem-hotfixes` 目录

指定目录下需要打包的路径，根据对应版本，发布日期

传递参数 `HOTFIX_YAML_PATH`，读取 hotfix charts 的路径
传递参数 `PRODUCT_NAME`，针对产品线的名称，例如 `compass` 或者 `clever`

```bash
bash hotfix.sh hotfix /root/release-hotfixes/2.7.x/2018xxxx compass
```

最终会在脚本当前的目录下生成 `./hotfixes` 的目录

#### 上传

传递参数 `UPLOAD_OSS_PATH`，上传 oss 的路径
传递参数 `PRODUCT_NAME`，针对产品线的名称，例如 `compass` 或者 `clever`

```bash
bash hotfix.sh upload compass-v2.7.x/ compass
```

待脚本结束，需去 oss 上确认是否上传成功，最终会上传至路径 `oss://infra-release/platform/compass-v2.7.x/hotfixes/2018xxxx/...`

