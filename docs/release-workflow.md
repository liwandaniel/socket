<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [release 发布流程](#release-%E5%8F%91%E5%B8%83%E6%B5%81%E7%A8%8B)
  - [准备工作](#%E5%87%86%E5%A4%87%E5%B7%A5%E4%BD%9C)
  - [自测日](#%E8%87%AA%E6%B5%8B%E6%97%A5)
    - [冒烟测试](#%E5%86%92%E7%83%9F%E6%B5%8B%E8%AF%95)
    - [更新 repo tag](#%E6%9B%B4%E6%96%B0-repo-tag)
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

### 更新 repo tag

研发代码 merge 之后，需要打新的 tag 触发流水线构建镜像

打包工具提供根据 repo tag 替换镜像 tag，只需在 yaml 中加上环境变量 `[[ imageTagFromGitTag ]]` 即可替换

```
image: '[[ registry_release ]]/hodor:[[ imageTagFromGitTag ]]'
```

不经常更新的组件，可以在 yaml 中指定镜像版本，并更新至最新的 tag 下

发布之前需要确保镜像已经推送到流水线仓库，如需替换的镜像 tag 需要和 repo tag 保持一致

### 推送镜像

- 镜像统一由流水线构建并推送 `cargo-infra.caicloud.xyz`
- 产品定制镜像，推送 `devops_release` 项目
- 上游镜像，推送 `library` 项目

## 发布日

**以下事项由 release team 负责，发布日晚七点前完成，否则算发布失败。若失败，请总结（[demo](https://github.com/caicloud/platform/issues/683)）**：

### 打包流程

参考 [标准产品打包发布流程](./package.md)
参考 [ OEM 打包发布流程](./oem-package.md)

### 测试发布

根据测试用例，自测部署包，测试完成后上传 OSS

按照 [Compass 容器云平台部署手册](https://docs.google.com/document/d/1BrLNUsbSpDM_v4Owv97fLCnG_ccIA2eULu8_Sx80Eyc/edit#heading=h.2yy1aubfzm7r) 进行安装