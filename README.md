<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [compass-release](#compass-release)
  - [产品版本安装包](#%E4%BA%A7%E5%93%81%E7%89%88%E6%9C%AC%E5%AE%89%E8%A3%85%E5%8C%85)
  - [产品插件安装包](#%E4%BA%A7%E5%93%81%E6%8F%92%E4%BB%B6%E5%AE%89%E8%A3%85%E5%8C%85)
    - [发布流程](#%E5%8F%91%E5%B8%83%E6%B5%81%E7%A8%8B)
      - [发起 pull request](#%E5%8F%91%E8%B5%B7-pull-request)
      - [审核 pull request](#%E5%AE%A1%E6%A0%B8-pull-request)
      - [同步镜像](#%E5%90%8C%E6%AD%A5%E9%95%9C%E5%83%8F)
      - [打包上传](#%E6%89%93%E5%8C%85%E4%B8%8A%E4%BC%A0)
    - [安装流程](#%E5%AE%89%E8%A3%85%E6%B5%81%E7%A8%8B)
  - [组件热升级安装包](#%E7%BB%84%E4%BB%B6%E7%83%AD%E5%8D%87%E7%BA%A7%E5%AE%89%E8%A3%85%E5%8C%85)
    - [发布流程](#%E5%8F%91%E5%B8%83%E6%B5%81%E7%A8%8B-1)
      - [发起 pull request](#%E5%8F%91%E8%B5%B7-pull-request-1)
      - [审核 pull request](#%E5%AE%A1%E6%A0%B8-pull-request-1)
      - [同步镜像](#%E5%90%8C%E6%AD%A5%E9%95%9C%E5%83%8F-1)
      - [打包上传](#%E6%89%93%E5%8C%85%E4%B8%8A%E4%BC%A0-1)
    - [安装流程](#%E5%AE%89%E8%A3%85%E6%B5%81%E7%A8%8B-1)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# compass-release

Compass 平台发布以安装包为最终介质，包含三类：

* 产品版本安装包，如 `Compass 2.7.0` 版本
* 产品插件安装包，如 `compass-plugins-<plugin>.tar.gz` 安装包
* 组件热升级安装包，如 `compass-hotfixes-<addon>.tar.gz` 安装包

## 产品版本安装包

说明详见部署手册，发布流程由 platform-release/infra 小组管理并提供工具。

## 产品插件安装包

```
oss://infra-release/plugins/<plugin-name>/compass-plugins-<plugin-name>-VERSION.tar.gz

compass-plugins-<plugin-name>-VERSION
├── <plugin-name>-<image-1>-VERSION-image.tar.gz
├── <plugin-name>-<image-2>-VERSION-image.tar.gz
├── ...
└── <plugin-name>.yaml
```

* 大多数情况下一个镜像，可能有多个
* yaml 符合插件中心 API 格式要求
* `VERSION` 使用 `v0.0.0`

### 发布流程

使用目录 `release-plugins`，按以下流程由工程师发起 pull request，
由 platform-release 小组同步镜像，由 infra 小组打包并上传。

#### 发起 pull request

[样例 pull request: #16](https://github.com/caicloud/compass-release/pull/16)

```
**Release note**:

/kind release
/queue need-queue
```

* 仅修改 `release-plugins/<plugin-name>.yaml` ：
  * 定义明确自增的 `spec.version` 作为插件版本
  * `spec.service.image` 使用 `harbor.caicloud.xyz/release/compass-plugins-<plugin-name>:VERSION` 的格式
  * 避免多个插件配置中槽位（ slots ）和端口冲突
* pr 除了 `/cc @plugin-owner` 之外需要：
  * `/cc @supereagle` 以知会 platform-release 小组
  * `/cc @pendoragon` 以知会 infra 小组

#### 审核 pull request

工程师需确保所有镜像推到内网 Cargo 且 `@plugin-owner` 审核内容无误后，
需给出以下指令：

```
image(s) pushed to
cargo.caicloudprivatetest.com/caicloud/compass-plugins-<plugin-name>:VERSION
...
/queue patches-need-sync-image
```

#### 同步镜像

platform-release 小组需查看 `label:queue/patches-need-sync-image label:kind/release` 的
pull requests；将所有镜像从 `cargo.caicloudprivatetest.com/caicloud` 同步到
`harbor.caicloud.xyz/release` 后给出指令 `/queue patches-need-package` 。

#### 打包上传

infra 小组需查看 `label:queue/patches-need-package label:kind/release` 的
pull requests；将所有镜像保存到 `tar.gz` 包；和 yaml 一起打包上传到 `oss://infra-release/plugins` 。

### 安装流程

参考部署手册。

## 组件热升级安装包

```
oss://infra-release/hotfixes/compass/v2.7.0/compass-hotfixes-<addon-name>-HOTFIXVERSION.tar.gz

compass-hotfixes-<addon-name>-HOTFIXVERSION
├── <addon-name>-<image-1>-HOTFIXVERSION-image.tar.gz
├── <addon-name>-<image-2>-HOTFIXVERSION-image.tar.gz
├── ...
└── <namespace>(default or kube-system)
        └── <addon-group-name>
                └── <addon-name>
                        └── values.yaml
```

* 一个安装包热修复一个 addon
* 大多数情况下一个镜像，可能有多个
* yaml 内容和组织方式，符合 [pangolin addons](https://github.com/caicloud/pangolin/tree/master/addons) 规范
* `HOTFIXVERSION` 不要用产品版本的形式，用 `v2.7.0-20180605-p1` 这种带基准产品版本和时间的格式

### 发布流程

使用目录 `release-hotfixes`，按以下流程由工程师发起 pull request，
由 platform-release 小组同步镜像，由 infra 小组打包并上传。

#### 发起 pull request

[样例 pull request: #TBD](https://github.com/caicloud/compass-release)

```
**Release note**:

/kind release
/queue need-queue
```

* 仅修改 `release-plugins/v2.7.0/<addon-name>-HOTFIXVERSION/<namespace>/<addon-group-name>/<addon-name>/values.yaml`
  * 大部分时间仅修改 `_config.controllers[0].containers[0].image`, 格式为 `[[ registry_release ]]/<addon-component>:HOTFIXVERSION`
  * 也有可能修改 `controllers[x]` 下的其他配置字段
* pr 除了 `/cc @plugin-owner` 之外需要：
  * `/cc @supereagle` 以知会 platform-release 小组
  * `/cc @pendoragon` 以知会 infra 小组

#### 审核 pull request

工程师需确保所有镜像推到内网 Cargo 且 `@plugin-owner` 审核内容无误后，
需给出以下指令：

```
image(s) pushed to
cargo.caicloudprivatetest.com/caicloud/addon-component:HOTFIXVERSION
...
/queue patches-need-sync-image
```

#### 同步镜像

platform-release 小组需查看 `label:queue/patches-need-sync-image label:kind/release` 的
pull requests；将所有镜像从 `cargo.caicloudprivatetest.com/caicloud` 同步到
`harbor.caicloud.xyz/release` 后给出指令 `/queue patches-need-package` 。

#### 打包上传

infra 小组需查看 `label:queue/patches-need-package label:kind/release` 的
pull requests；将所有镜像保存到 `tar.gz` 包；和 yaml 一起打包上传到 `oss://infra-release/hotfixes` 。

### 安装流程

参考部署手册。
