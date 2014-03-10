## 插件
### 运行时
RP3 会安装下列语言的运行时

* PHP
* Python
* Golang
* Node

### 服务

* MySQL

	使用 MariaDB 实现，只监听本地端口，支持引擎：

	* MyISAM (默认)
	* XtraDB(InnoDB)

	需要提供一个类似 phpMyAdmin 的 GUI

	* 权限控制

		每个用户对『以自己的用户名为前缀的数据库』有操作权限
		例如 jysperm 可以访问 jysperm_db

	* 面板操作

		* 设置 MySQL 密码

	* 资源监控

		* 磁盘占用
		* 查询数量(折合为 CPU 时间，延后实现)
		* XtraDB 的使用情况(折合为内存使用), 因为 XtraDB 比较消耗内存，延后实现


* MongoDB

	MongoDB 开启 --auth 选项
	权限控制：每个用户对『以自己的用户名为前缀的数据库』有操作权限

	* 面板操作：

		* 新建数据库
		* 重置数据库权限
		* 删除数据库

	* 资源监控

		* 磁盘占用
		* 其他指标，延后实现

* SSH

	* 面板操作：

		* 设置 SSH 密码
		* 结束所有进程
		* 重置文件权限

	* 资源监控

		* 进程使用的 CPU 时间
		* 进程使用的内存
		* home 目录的磁盘空间

* Nginx

	该插件直接对输入的 Nginx 配置文件进行解析，进行安全性检查。
	然后将配置文件写入 Nginx, 重新加载 Nginx.

	配置文件以站点为单位，每个站点可以暂时启用和禁用

	* 同时提供一个 GUI 辅助用户编写配置文件
	* [支持的配置文件指令](https://gist.github.com/jysperm/6479965)

	* 面板操作

		* 新建/修改/删除站点

	* 资源监控

		可以靠根据日志来统计，或者编写 Nginx 模块

		* 请求数
		* 流量

* PHP-FPM

	为每个用户跑一个 PHP-FPM 进程池，并通过 Unix Socket 连接
	该功能只是默认的 PHP 支持，用户完全可以运行自己的 PHP-FPM 实现深度定制。

	* 面板操作

		* 启用/关闭 PHP-FPM

	* 资源监控

		纳入 SSH 资源监控

* ShadowSocks

	为每个用户使用单独的端口和密码。

	* 面板操作

		* 启用/关闭 ShadowSocks
		* 设置密码

	* 资源监控

		可能需要修改其源代码

		* 流量

* PPTP VPN

	* 面板操作

		* 设置密码

	* 资源监控

		可能需要修改其源代码

		* 流量

* Memcached

	为每个用户跑一个 Memcached, 并通过 Unix Socket 连接

	* 面板操作

		* 启用/关闭 Memcached
		* 设置缓存内存大小

	* 资源监控

		纳入 SSH 资源监控

### 功能插件

* 用户手册
* 用户剩余时长计数器
* Bitcoin 支付
* 支付宝担保交易
