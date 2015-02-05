# RootPanel
RootPanel 是一个 PaaS 开发框架，提供了用户系统、计费和订单系统、工单系统，允许通过开发插件的方式来支持各种网络服务的管理和销售，默认实现了一些插件来支持例如虚拟主机，ShadowSocks 等常见服务，用户也可以简单地自行编写插件来拓展 RootPanel 的功能。

RootPanel 具有良好的设计，高度的可定制性，支持多语言和多时区，以及非常高的单元测试覆盖率。

RootPanel 的文档位于 [Github Wiki](https://github.com/jysperm/RootPanel/wiki), 包括常见问题、终端用户文档、使用文档、开发文档。

## 安装

稳定版本
[![Build Status](https://travis-ci.org/jysperm/RootPanel.svg?branch=stable)](https://travis-ci.org/jysperm/RootPanel)

    git clone -b stable https://github.com/jysperm/RootPanel.git

主分支
[![Build Status](https://travis-ci.org/jysperm/RootPanel.svg?branch=master)](https://travis-ci.org/jysperm/RootPanel)

    git clone https://github.com/jysperm/RootPanel.git

试运行和开发推荐使用 Vagrant: `vagrant up`

详细安装步骤：[INSTALL.md](https://github.com/jysperm/RootPanel/blob/master/INSTALL.md)

## 配置文件示例

请从 `sample` 中选择一个配置文件复制到根目录，重命名为 `config.coffee`:

    core.config.coffee         # 仅核心模块
    rpvhost.config.coffee      # 虚拟主机 (正在重构，目前支持 SSH 和 Supervisor)
    shadowsocks.config.coffee  # ShadowSocks 代理服务

## 从旧版本升级

    # 停止 RootPanel
    supervisorctl stop RootPanel

    # 备份数据库
    mongodump --authenticationDatabase admin --db RootPanel --out .backup/db -u rpadmin -p

    # 更新源代码
    git pull

根据 `/migration/system` 中新增的说明文件，执行相应命令来修改系统设置，如果跨越多个版本需要依次执行。
检查更新日志和 `/sample` 中的默认配置文件，视情况修改配置文件(`config.coffee`).

    # 升级数据库
    npm run migrate

    # 应用新的设置
    npm run reconfigure

    # 启动 RootPanel
    supervisorctl start RootPanel

## 技术构成

* 前端：Bootstrap, jQuery, Jade, Less
* 后端：Express, Coffee
* 数据库：MongoDB, Redis
* 操作系统支持：Ubuntu 14.04 amd64

RootPanel 默认会通过 Google Analytics 向开发人员发送匿名的统计信息。

## 开发情况：

* [ChangeLog](https://github.com/jysperm/RootPanel/blob/master/CHANGELOG.md)
* [Releases](https://github.com/jysperm/RootPanel/releases)
* [TODO List](https://github.com/jysperm/RootPanel/labels/TODO)

贡献列表(v0.8.0):

* jysperm 10149 lines 98%
* yudong 48 lines 1.6%
* kanakin 38 lines 0.4%

贡献须知：当你向 RootPanel 贡献代码时，即代表你同意授予 RootPanel 维护团队永久的，不可撤回的代码使用权，包括但不限于以闭源的形式出售商业授权。
在你首次向 RootPanel 贡献代码时，我们还会人工向你确认一次上述协议。

## 许可协议
RootPanel 采用开源与商业双授权模式。

* 开源授权：[AGPLv3](https://github.com/jysperm/RootPanel/blob/master/LICENSE) | [CC-SA](http://creativecommons.org/licenses/sa/1.0/) (文档) | Public Domain (配置文件和示例)
* 商业授权(计划中)
* 有关授权的 [FAQ](https://github.com/jysperm/RootPanel/wiki/%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98#%E6%8E%88%E6%9D%83)
