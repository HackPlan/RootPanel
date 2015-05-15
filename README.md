# RootPanel
A pluggable PaaS service development framework  
一个插件化的 PaaS 服务开发框架

* 提供 用户管理、计费和订单管理、工单管理 等功能
* 提供了一个可拓展的框架来支持新的服务类型
* 良好的设计，高单元测试覆盖率，多语言支持

官网和文档位于 [rootpanel.io](http://rootpanel.io/docs/).

## 安装

项目中已包含 Vagrantfile 和 Dockerfile, 可以直接创建 RootPanel 的运行环境；或者可以参考详细安装步骤：[INSTALL.md](https://github.com/jysperm/RootPanel/blob/master/INSTALL.md)

## 技术构成

* 前端 Bootstrap, Backbone, jQuery, Less, Jade
* 后端 Node.js, Coffee
* 数据库 MongoDB, Redis
* 操作系统 Ubuntu/Debian

RootPanel 默认会通过 Google Analytics 向开发人员发送匿名的统计信息。

开发情况：

* [ChangeLog](https://github.com/jysperm/RootPanel/blob/master/CHANGELOG.md)
* [Releases](https://github.com/jysperm/RootPanel/releases)
* [TODO List](https://github.com/jysperm/RootPanel/labels/TODO)

v0.8.0 开发者列表：

* jysperm 10149 lines 98%
* yudong 48 lines 1.6%
* kanakin 38 lines 0.4%

贡献须知：当你向 RootPanel 贡献代码时，即代表你同意授予 RootPanel 维护团队永久的，不可撤回的代码使用权，包括但不限于以闭源的形式出售商业授权。
在你首次向 RootPanel 贡献代码时，我们还会人工向你确认一次上述协议。

## 许可协议
RootPanel 采用开源与商业双授权模式。

* 开源授权：[AGPLv3](https://github.com/jysperm/RootPanel/blob/master/LICENSE) | [CC-SA](http://creativecommons.org/licenses/sa/1.0) (文档)
* 商业授权（计划中）
* 有关授权的 [FAQ](https://github.com/jysperm/RootPanel/wiki/%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98#%E6%8E%88%E6%9D%83)
