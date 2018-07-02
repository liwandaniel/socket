<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [compass-release](#compass-release)
  - [产品版本安装包](#%E4%BA%A7%E5%93%81%E7%89%88%E6%9C%AC%E5%AE%89%E8%A3%85%E5%8C%85)
  - [产品组件热升级安装包](#%E4%BA%A7%E5%93%81%E7%BB%84%E4%BB%B6%E7%83%AD%E5%8D%87%E7%BA%A7%E5%AE%89%E8%A3%85%E5%8C%85)
    - [发布流程](#%E5%8F%91%E5%B8%83%E6%B5%81%E7%A8%8B)
      - [发起 pull request](#%E5%8F%91%E8%B5%B7-pull-request)
      - [审核 pull request](#%E5%AE%A1%E6%A0%B8-pull-request)
      - [同步镜像 & 打包上传](#%E5%90%8C%E6%AD%A5%E9%95%9C%E5%83%8F--%E6%89%93%E5%8C%85%E4%B8%8A%E4%BC%A0)
    - [安装流程](#%E5%AE%89%E8%A3%85%E6%B5%81%E7%A8%8B)
  - [产品插件安装包](#%E4%BA%A7%E5%93%81%E6%8F%92%E4%BB%B6%E5%AE%89%E8%A3%85%E5%8C%85)
    - [发布流程](#%E5%8F%91%E5%B8%83%E6%B5%81%E7%A8%8B-1)
      - [发起 pull request](#%E5%8F%91%E8%B5%B7-pull-request-1)
      - [审核 pull request](#%E5%AE%A1%E6%A0%B8-pull-request-1)
      - [同步镜像 & 打包上传](#%E5%90%8C%E6%AD%A5%E9%95%9C%E5%83%8F--%E6%89%93%E5%8C%85%E4%B8%8A%E4%BC%A0-1)
    - [安装流程](#%E5%AE%89%E8%A3%85%E6%B5%81%E7%A8%8B-1)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# compass-release

Compass 平台发布以安装包为最终介质，包含三类：

* 产品版本安装包，如 `compass-2.7.0/*` 版本
* 产品组件热升级安装包，如 `compass-hotfixes-<desc>-<addon>-<VERSION>.tar.gz` 安装包
* 产品插件安装包，如 `compass-plugins-<plugin>-<VERSION>.tar.gz` 安装包

## 产品版本安装包

```
# Describe directory
oss://infra-release/platform/
├── compass-v2.7.0-ga/
│   ├── infra-<VERSION>.tar.gz
│   ├── cargo-<VERSION>.tar.gz
│   ├── compass-kernel-<VERSION>.tar.gz
│   ├── compass-component-<VERSION>.tar.gz
│   └── hotfixes
│       ├── 20180701
│       │    ├── compass-hotfixes-<desc>-<addon-name-1>-20180701-<VERSION>.tar.gz
│       │    ├── ...
│       │    └── compass-hotfixes-<desc>-<addon-name-x>-20180701-<VERSION>.tar.gz
│       ├── 20180707
│       │    └── ...
│       └── ...
├── compass-v2.7.0/
│   └── ...
└── compass-v2.7.1/
    └── ...
```

安装包的格式说明详见部署手册，发布流程由 platform-release 和 infra 小组管理并提供工具。

## 产品组件热升级安装包

```
# Describe directory
oss://infra-release/platform/
├── compass-v2.7.0-ga/
│   ├── ...
│   └── hotfixes
│       ├── 20180701
│       │    ├── compass-hotfixes-<desc>-<addon-name-1>-20180701-<VERSION>.tar.gz
│       │    ├── ...
│       │    └── compass-hotfixes-<desc>-<addon-name-x>-20180701-<VERSION>.tar.gz
│       ├── 20180707
│       │    └── ...
│       └── ...
├── compass-v2.7.0/
│   ├── ...
│   └── hotfixes
│       └── ...
└── compass-v2.7.1/
    └── ...

# Describe package
compass-hotfixes-<desc>-<addon-name-x>-<VERSION>.tar.gz
├── <addon-name>-<image-1>-<VERSION>-image.tar.gz
├── <addon-name>-<image-2>-<VERSION>-image.tar.gz
├── ...
└── <namespace>(default or kube-system)
        └── <addon-group-name>
                └── <addon-name>
                        └── values.yaml
```

* `<desc>` 使用 `(feat|bug)<number>` 的格式
  * `featxxx` 表示这是一项紧急（P0）需求实现交付的热升级，必须有对应的 `caicloud/platform` 项目。例如`feat714` 指交付 https://github.com/caicloud/platform/issues/714 的修改
  * `bugxxx` 表示这是一项紧急（P0）问题修复交付的热升级，必须有对应的 `caicloud/prod-issue` 项目。例如 `bug227` 指交付 https://github.com/caicloud/prod-issue/issues/227 的修改
* 一个安装包热修复一个 addon
* 大多数情况下一个镜像，可能有多个
* yaml 内容和组织方式，符合 [pangolin addons](https://github.com/caicloud/pangolin/tree/master/addons) 规范

### 发布流程

使用目录 `release-hotfixes`，按以下流程由工程师发起 pull request，
由 platform-release 小组同步镜像，并打包上传。

#### 发起 pull request

[样例 pull request: #24](https://github.com/caicloud/compass-release/pull/24)

```
**Release note**:

/kind release
/queue need-queue
```

* 仅修改 `release-plugins/v2.7.0/<desc>-<addon-name>-<VERSION>/<namespace>/<addon-group-name>/<addon-name>/values.yaml`
  * 大部分时间仅修改 `_config.controllers[0].containers[0].image`, 格式为 `[[ registry_release ]]/<addon-component>:<VERSION>`
  * 也有可能修改 `controllers[x]` 下的其他配置字段
* pr 除了 `/cc @plugin-owner` 之外需要：
  * `/cc @supereagle` 以知会 platform-release 小组

#### 审核 pull request

工程师需确保所有镜像推到内网 Cargo 且 `@plugin-owner` 审核内容无误后，
需给出以下指令：

```
image(s) pushed to
cargo.caicloudprivatetest.com/caicloud/addon-component:<VERSION>
...
/queue working-image-pushed
```

#### 同步镜像 & 打包上传

platform-release 小组需查看 `label:queue/working-image-pushed label:kind/release` 的
pull requests；将所有镜像从 `cargo.caicloudprivatetest.com/caicloud` 同步到
`harbor.caicloud.xyz/release` ；将所有镜像保存到 `tar.gz` 包；和 yaml 一起打包上传到
`oss://infra-release/platform/**/hotfixes` ；确认上传完成后，需给出以下指令：
```
packages uploaded to
oss://infra-release/platform/compass-v2.7.0/hotfixes/compass-hotfixes-<desc>-<addon-name>-<VERSION>.tar.gz
...
/queue done-package-uploaded
```

注：如果一个安装包要针对多个版本，需在每个版本对应的 hotfixes 目录都上传一遍。

### 安装流程

参考部署手册。

## 产品插件安装包

```
# Describe directory
oss://infra-release/platform/plugins/
├── compass-plugins-<plugin-name-1>
├── compass-plugins-<plugin-name-2>
├── ...
└── compass-plugins-<plugin-name-x>
    ├── compass-plugins-<plugin-name-x>-<VERSION-1>.tar.gz
    ├── ...
    └── compass-plugins-<plugin-name-x>-<VERSION-y>.tar.gz

# Describe package
compass-plugins-<plugin-name>-<VERSION>.tar.gz
├── compass-plugins-<plugin-name>-<image-1>-<VERSION>-image.tar.gz
├── compass-plugins-<plugin-name>-<image-2>-<VERSION>-image.tar.gz
├── ...
└── compass-plugins-<plugin-name>.yaml
```

* 大多数情况下安装包一个镜像，可能有多个
* yaml 符合插件中心 API 格式要求
* `VERSION` 使用 `v0.0.0`

### 发布流程

使用目录 `release-plugins`，按以下流程由工程师发起 pull request，
由 platform-release 小组同步镜像，并打包上传。

#### 发起 pull request

[样例 pull request: #16](https://github.com/caicloud/compass-release/pull/16)

```
**Release note**:

/kind release
/queue need-queue
```

* 仅修改 `release-plugins/<plugin-name>.yaml` ：
  * 定义明确自增的 `spec.version` 作为插件版本
  * `spec.service.image` 使用 `harbor.caicloud.xyz/release/compass-plugins-<plugin-name>:<VERSION>` 的格式
  * 避免多个插件配置中槽位（ slots ）和端口冲突
* pr 除了 `/cc @plugin-owner` 之外需要：
  * `/cc @supereagle` 以知会 platform-release 小组

#### 审核 pull request

工程师需确保所有镜像推到内网 Cargo 且 `@plugin-owner` 审核内容无误后，
需给出以下指令：

```
image(s) pushed to
cargo.caicloudprivatetest.com/caicloud/compass-plugins-<plugin-name>:<VERSION>
...
/queue working-image-pushed
```

#### 同步镜像 & 打包上传

platform-release 小组需查看 `label:queue/working-image-pushed label:kind/release` 的
pull requests；将所有镜像从 `cargo.caicloudprivatetest.com/caicloud` 同步到
`harbor.caicloud.xyz/release` ；将所有镜像保存到 `tar.gz` 包；和 yaml 一起打包上传到
`oss://infra-release/platform/plugins/` ；确认上传完成后，需给出以下指令：
```
packages uploaded to
oss://infra-release/platform/plugins/<plugin-name>/compass-plugins-<plugin-name>-VERSION.tar.gz
...
/queue done-package-uploaded
```

### 安装流程

参考部署手册。
