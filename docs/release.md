<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [OEM Release](#oem-release)
  - [Fork the main repository](#fork-the-main-repository)
  - [Create your clone](#create-your-clone)
  - [Change to OEM branch](#change-to-oem-branch)
  - [Prerequisite](#prerequisite)
  - [Collect OEM charts (optional)](#collect-oem-charts-optional)
    - [Collect & Update tags](#collect--update-tags)
    - [Collect Charts](#collect-charts)
  - [Update image list](#update-image-list)
  - [Archive](#archive)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# OEM Release

## Fork the main repository

```txt
1. Go to https://github.com/caicloud/product-release
2. Click the "Fork" button (at the top right)
```

## Create your clone

执行以下命令：

```bash
git clone https://github.com/$GITHUB_USERNAME/product-release.git
# or: git clone git@github.com:$GITHUB_USERNAME/product-release.git
```

使用你的 GitHub profile name 替换 $GITHUB_USERNAME。

## Change to OEM branch

```bash
cd product-release
git checkout oem-branch
```

## Prerequisite

通过 https://github.com/settings/tokens/new?scopes=repo 创建一个 GitHub OAuth token。

保存到指定文件中：

```bash
echo $GITHUB_OAUTH_TOKEN > token
```

使用新的 GitHub OAuth token 替换 $GITHUB_OAUTH_TOKEN。

## Collect OEM charts (optional)

若有 chart 保存在组件 repository 根目录的 `release` 目录下，可通过 [chart 收集工具](https://github.com/caicloud/pangolin/tree/master/cmd/amctl)统一收集到 `oem-addons` 目录下。

若无，跳转至 [Update image list](#update-image-list)

### Collect & Update tags

执行以下命令：

```bash
make update-tag CHART_LIST_PATH=./charts_list.yaml GITHUB_TOKEN_PATH=./token TARGET_COLLECT_TAG_PATH=./release_charts.yaml
```

上述命令将自动获取各个 repo 最新 tag 并生成 `release_charts.yaml` 用于下一步收集 chart。

提交 `release_charts.yaml` 并发起 PR, `/assign` 各个组件的负责人确认 `release_charts.yaml` 文件中的 tag, 由各负责人确保：

- 需要替换的镜像 tag 和 repo tag 一致
- 对应的 repo 上，改 tag 的 release 目录下有正确的 chart 文件

### Collect Charts

确认 tag 之后，执行以下命令：

```bash
make collect-charts ADDONS_PATH=./oem-addons GITHUB_TOKEN_PATH=./token TARGET_COLLECT_TAG_PATH=./release_charts.yaml
```

上述命令将自动收集 Charts 文件并保存在 `./oem-addons` 目录下。

## Update image list

执行以下命令：

```bash
make convert-images ADDONS_PATH=./oem-addons TARGET_IMGAES_LIST_PATH=./images-lists/images_platform.list 
```

上述命令将自动收集 Charts 中固定格式的镜像并保存在 `./oem-images-lists/images_platform.list` 中。

**若镜像不在 Charts 或者具有特殊格式，请单独创建文件并保存至 `./oem-images-lists` 中。**

## Archive

提交 `./oem-addons` & `./oem-images-lists` 并发起 PR 归档。

待 PR 合入以后，打上最新的 release tag。
