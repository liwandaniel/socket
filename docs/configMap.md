<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [comfigMap 配置](#comfigmap-%E9%85%8D%E7%BD%AE)
  - [platform-info (系统参数)](#platform-info-%E7%B3%BB%E7%BB%9F%E5%8F%82%E6%95%B0)
  - [platform-config (平台参数)](#platform-config-%E5%B9%B3%E5%8F%B0%E5%8F%82%E6%95%B0)
    - [配置方法](#%E9%85%8D%E7%BD%AE%E6%96%B9%E6%B3%95)
  - [如何使用配置](#%E5%A6%82%E4%BD%95%E4%BD%BF%E7%94%A8%E9%85%8D%E7%BD%AE)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## comfigMap 配置

参数配置分为两类：

* [系统参数](#platform-info-%E7%B3%BB%E7%BB%9F%E5%8F%82%E6%95%B0)
* [平台参数](#platform-config-%E5%B9%B3%E5%8F%B0%E5%8F%82%E6%95%B0)

### platform-info (系统参数)

来自于 Vaquita 部署好后的系统信息，只能从 system-info 中读取。例如：release harbor 地址，control cluster endpoint

* 不可配置

### platform-config (平台参数)

平台业务配置，通过配置文件作为入口生成。例如：单/多租户，SMTP，OIDC

#### 配置方法

在 [platform-config.yaml.j2](../platform-config.yaml.j2) 模板文件的 data 中添加变量

* key 和 value 要保持一致的命名

* value 要用双花括号和空格定义，如下

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: platform-config
data:
  variable-name: "{{ variable-name }}"
```

在 [config.sample](../config.sample) 模板文件中添加相同变量名

* 用 `=` 赋值，此处所填的值就是生成的 configMap 中最终的值

```
# 备注说明
variable-name="value"
```

此处生成的 configMap 会替换集群中已经存在的 configMap，如果不需要修改，需要和 `product-release` mater 分支上的文件保持一致

### 如何使用配置

在组件的 [chart](../addons) 文件中使用配置，可以选择挂载的方式，和直接生成配置的方式

**挂载 configMap**

按照如下方式修改 [chart](../addons) 文件中的配置

```
- name: CAICLOUD_PRODUCT_CFG_STRING_MULTI_TENANCY
from:
  type: Config
  name: platform-config
  key: "tenantMode"
```

* 如果 configMap 发生改动，需要重启挂载了 configMap 的 pod 以获取配置信息

**替换变量名**

以方括号加空格形式添加变量名，部署组件时会根据 configMap 中的 value 自动替换变量的值

```
- name: CAICLOUD_PRODUCT_CFG_STRING_MULTI_TENANCY
  value: '[[ tenantMode ]]'
```
