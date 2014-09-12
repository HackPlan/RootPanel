# RootPanel
## 简介
RootPanel 是一个高度插件化的，基于 Linux 的虚拟服务销售平台，目标是成为虚拟主机界的 WordPress.

它的核心功能包括：用户和计费系统，工单系统，管理员面板；其余具体的功能均以插件实现，RootPanel 支持的典型服务有：

* Linux 虚拟主机(Nginx, PHP, MySQL, MongoDB)

    即最传统的，将一台 Linux 服务器划分给多个用户的方式。  
    示例站点：<http://us1.rpvhost.net>

* ShadowSocks 代理服务

    按实际使用流量实时结算的 ShadowSocks 代理。  
    示例站点：<http://greenshadow.net>

* 朋友合租(开发中)
* Xen VPS(开发中)

## 安装和使用

开发版本：

    git clone https://github.com/jysperm/RootPanel.git

稳定版本：

    npm install -g rootpanel

详细安装说明：[INSTALL.md](https://github.com/jysperm/RootPanel/blob/master/INSTALL.md)

全局命令：

    rp-fix-permissions  # 修复文件系统权限
    rp-migration        # 版本间数据库迁移脚本
    rp-system-sync      # 与操作系统同步信息
    rp-clean            # 清理冗余数据

运行：

    node start.js

配置文件示例(sample 目录):

    core.config.coffee          # 仅核心模块
    shadowsocks.config.coffee   # ShadowSocks 代理服务
    full.config.coffee          # 全功能虚拟主机
    php-vhost.config.coffee     # PHP/MySQL 虚拟主机
    node-vhost.config.coffee    # Node.js/Python/Golang 虚拟主机
    share-vps.config.coffee     # 朋友合租
    static.config.coffee        # 静态文件托管
    git.config.coffee           # Git 托管
    xen.config.coffee           # Xen VPS

请选择一个配置文件复制到根目录，重命名为 `config.coffee`.

## Vagrant
<https://vagrantcloud.com/jysperm/boxes/rootpanel>

## 技术构成

* 前端：Bootstrap(3), jQuery, Jade, Less
* 后端：Express, Coffee
* 数据库：MongoDB(2.4), Redis
* 操作系统支持：Ubuntu 14.04 amd64

## 开发情况：

* [ChangeLog](https://github.com/jysperm/RootPanel/blob/master/CHANGELOG.md) | [Releases](https://github.com/jysperm/RootPanel/releases)
* [TODO List](https://github.com/jysperm/RootPanel/labels/TODO)

授权：

* [AGPLv3](https://github.com/jysperm/RootPanel/blob/master/LICENSE)
* 商业授权(计划中)

贡献列表(v0.7.1):

* jysperm 7542 lines 98.6%
* yudong 48 lines 0.6%
* Akiyori 42 lines 0.5%
* Tianhao Xiao 17 lines 0.2%
