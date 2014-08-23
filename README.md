# RootPanel
## 简介
RootPanel 是一个高度插件化的，基于 Linux 的虚拟服务销售平台，目标是成为虚拟主机界的 WordPress.

它的核心功能包括：用户和计费系统，工单系统，管理员面板；其余具体的功能均以插件实现，RootPanel 支持的典型服务有：

* Linux 虚拟主机(Nginx, PHP, MySQL, MongoDB, Memcached)

    即最传统的，将一台 Linux 服务器划分给多个用户的方式。
    示例站点：<http://us1.rpvhost.net>

* ShadowSocks 代理服务

    按实际使用流量实时结算的 ShadowSocks 代理。
    示例站点：<http://ss.rpvhost.net>

* Xen VPS(开发中)

## 安装和使用

开发版本：

    git clone https://github.com/jysperm/RootPanel.git

稳定版本：

    npm install -g rootpanel

详细安装说明：[INSTALL.md](https://github.com/jysperm/RootPanel/blob/master/INSTALL.md)

全局命令：

    rp-start            # 以 forever 启动
    rp-fix-permissions  # 修复文件系统权限
    rp-migration        # 版本间数据库迁移脚本
    rp-system-sync      # 与操作系统同步信息
    rp-clean            # 清理冗余数据

Makefile:

    make install    # 安装依赖
    make run        # 直接运行
    make test       # 运行测试(开发中)
    make start      # 以 forever 启动
    make restart    # 重启 forever 进程
    make stop       # 停止 forever 进程

配置文件：

    config.coffee

配置文件示例(sample 目录):

    shadowsocks.config.coffee   # ShadowSocks 代理服务
    linux-vhost.config.coffee   # Linux 虚拟主机

配置文件位于 `config.coffee`

## 技术构成

* 前端：Bootstrap(3), jQuery, Jade, Less
* 后端：Express, Coffee
* 数据库：MongoDB(2.4), Redis
* 操作系统支持：Ubuntu 14.04 amd64

## 开发情况：

* [ChangeLog](https://github.com/jysperm/RootPanel/blob/master/CHANGELOG.md) | [Releases](https://github.com/jysperm/RootPanel/releases)
* [TODO List](https://github.com/jysperm/RootPanel/labels/TODO)
* LICENSE: [GPLv3](https://github.com/jysperm/RootPanel/blob/master/LICENSE)