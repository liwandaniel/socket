<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [产品组件热升级安装包](#%E4%BA%A7%E5%93%81%E7%BB%84%E4%BB%B6%E7%83%AD%E5%8D%87%E7%BA%A7%E5%AE%89%E8%A3%85%E5%8C%85)
  - [发布流程](#%E5%8F%91%E5%B8%83%E6%B5%81%E7%A8%8B)
    - [发起 issue](#%E5%8F%91%E8%B5%B7-issue)
    - [发起 pull request & 制作 README.md](#%E5%8F%91%E8%B5%B7-pull-request--%E5%88%B6%E4%BD%9C-readmemd)
    - [审核 pull request](#%E5%AE%A1%E6%A0%B8-pull-request)
    - [同步镜像 & 打包上传](#%E5%90%8C%E6%AD%A5%E9%95%9C%E5%83%8F--%E6%89%93%E5%8C%85%E4%B8%8A%E4%BC%A0)
    - [安装包](#%E5%AE%89%E8%A3%85%E5%8C%85)
    - [紧急情况](#%E7%B4%A7%E6%80%A5%E6%83%85%E5%86%B5)
  - [安装流程](#%E5%AE%89%E8%A3%85%E6%B5%81%E7%A8%8B)
- [产品组特殊补丁安装包](#%E4%BA%A7%E5%93%81%E7%BB%84%E7%89%B9%E6%AE%8A%E8%A1%A5%E4%B8%81%E5%AE%89%E8%A3%85%E5%8C%85)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

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
│       │    ├── compass-hotfixes-<desc>-<addon-name-x>-20180701-<VERSION>.tar.gz
│       │    └── README.md
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

#### 发起 issue

PM 在 platform 发起 [hotfix issue](https://github.com/caicloud/platform/issues/new/choose)，issue 内包含

- hotfix 修复的 issue list
- hotfix 发布的注解（希望做到 issue 内容复制成 README.md 后能自解释 hotfix 内容）
- assign 相应地人员开展工作

[样例 issue: #818](https://github.com/caicloud/platform/issues/818)

#### 发起 pull request & 制作 README.md

**使用目录 `release-hotfixes`，由工程师按以下流程发起 pull request。**

[样例 pull request: #24](https://github.com/caicloud/compass-release/pull/24)

```
**Release note**:

/kind release
/queue need-queue
```
* 明确该 hotfix 针对的 Compass 版本，从本项目中该版本对应的 tag 中获得该组件的 values.yaml
* values.yaml 的 `_metedata.version` 按照 hotfix 组件的镜像版本修改
  * 例如更新 `console-web:v3.1.55`, `_metedata.version` 则需要改为`v3.1.55`
* 仅修改 `release-plugins/v2.7.0/<desc>-<addon-name>-<VERSION>/<namespace>/<addon-group-name>/<addon-name>/values.yaml`
  * 大部分时间仅修改 `_config.controllers[0].containers[0].image`, 格式为 `[[ registry_release ]]/<addon-component>:<VERSION>`
  * 也有可能修改 `controllers[x]` 下的其他配置字段
* pr 除了 `/cc @plugin-owner` 之外需要：
  * `@caicloud/platform-release` 以知会 platform-release 小组

**使用目录 `release-hotfixes`，由 PM 按以下规范制作 README.md 并发起 pull request。**

[样例 pull request：#81](https://github.com/caicloud/compass-release/pull/81)

#### 审核 pull request

工程师需确保对应组件 repo 打上 hotfix 的 tag、所有镜像推到内网 Cargo 且 `@plugin-owner` 审核内容无误后，
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
`harbor.caicloud.xyz/release` ；将所有镜像保存到 `tar.gz` 包，并和 yaml、README.md 一起打成 hotfix 包。

针对该 hotfix 对应的产品版本，准备相应的环境，严格按照部署文档中组件快速升级的步骤，安装 hotfix 并验证升级组件是否成功被更新（如果修复内容需要特殊复现环境，则开发自行准备自验环境），最终将包上传到 OSS。

包上传到 `oss://infra-release/platform/**/hotfixes` ；确认上传完成后，需给出以下指令：
```
packages uploaded to
oss://infra-release/platform/compass-v2.7.0/hotfixes/compass-hotfixes-<desc>-<addon-name>-<VERSION>.tar.gz
...
/queue done-package-uploaded
```

注：如果一个安装包要针对多个版本，需在每个版本对应的 hotfixes 目录都上传一遍。

#### 安装包

如果需要测试介入，由 PM 通知相关测试人员，测试人员从 oss 上拉取 hotfix 文件，参考/评审 README.md 验证 hotfix。
若验证不通过，则需要在 hotfix issue 中回复说明，PM & 开发 & release 重复前置步骤，且 PM 需组织复盘；
若验收通过则 hotfix 发布完成，并通知 PM，最后由 PM 回复并关闭相关 issue。

#### 紧急情况

特殊的，如前线要求紧急，开发用临时方案给前线提供**补丁/镜像**后，需要补充 issue, hotfix 及 README.md。针对临时方案的代码，以下两种方案：

1. 评估后可以上库，则上库后打 tag
2. 评估后不能上库，则提 pr 但不 merge，readme 中需要记录此 pr，pr 挂到后续 hotfix 的正式方案合入并发布后，才关闭临时方案 pr

无论临时方案代码属于上述哪一种，PM 都需要跟踪推动正式方案，落实正式 hotfix，以上完成后，临时方案 hotfix issue 才能关闭。

### 安装流程

参考[部署手册](https://docs.google.com/document/d/1BrLNUsbSpDM_v4Owv97fLCnG_ccIA2eULu8_Sx80Eyc/edit#heading=h.tn6y7bkv17bu)。

## 产品组特殊补丁安装包

```
# Describe directory
oss://infra-release/platform/
├── compass-v2.7.0-ga/
│   ├── ...
│   └── manual-fixes
│       ├── 20180801
│       │   ├── fix01(.tar.gz|txt)
│       │   ├── ...
│       │   └── fix0x(.tar.gz|txt)
│       ├── 20180808
│       │    └── ...
│       └── ...
├── compass-v2.7.0/
│   ├── ...
│   └── manual-fixes
│       └── ...
└── compass-v2.7.1/
    └── ...

# Describe package - freestyle
```

* 凡是非组件热升级的修复安装包都可视作特殊补丁安装包，包括但不限于：
  * infra 离线源修复，cargo 服务修复，k8s 修复等
  * 产品组件的数据 migration
* 安装包需由负责人自行取一个合理的名字
* 安装包的形式，可以是安装资源加脚本，也可以是操作指导文档，甚至是支撑工程师的 oncall 电话

安装包的源文件、发布打包版本流程也由负责工程师自行维护，
**安装流程必须在安装包内有文档或文档链接可查**，
包括操作步骤，是否可以重复执行，是否需要数据备份，以及出问题找哪个研发等信息。