## RootPanel3
RP3 是一个插件化的 Linux 虚拟主机管理和销售系统。

所谓虚拟主机就是指在同一个物理服务器(或 VPS)上，划分给多个用户使用，使其互不干扰。  
相比于 VPS, 虚拟主机实现的是应用级别的虚拟化，而不是操作系统级别的虚拟机。  
虚拟主机大概介于 PaaS(GAE, SAE) 和 IaaS 之间。

### 功能

RP3 的核心功能包括：

* 用户系统
* 工单系统
* 管理员面板

其他功能均以插件实现，包括 SSH, Nginx, PHP-FPM, MySQL, ShadowSocks 等等。

除此之外，RP3 支持：

* 非侵入式的安装

	可以定制相关配置文件的路径，可以与其他面板共存，可以同时手工管理。

* 国际化

	支持多语言，如果有人翻译的话

## 技术构成

* 前端：Bootstrap3, jQuery, Jade, Less
* 后端：Express, Coffee
* 数据库：MongoDB, Memcache

操作系统支持，按推荐程度排序：

* Debian
* Ubuntu
* Arch
* CentOS
