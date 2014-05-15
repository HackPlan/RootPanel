## RootPanel3
RP3 是一个插件化的 Linux 虚拟主机管理和销售系统。

所谓虚拟主机就是指在同一个物理服务器(或 VPS)上，划分给多个用户使用，使其互不干扰。  
相比于 VPS, 虚拟主机实现的是应用级别的虚拟化，而不是操作系统级别的虚拟机。  
虚拟主机大概介于 PaaS(GAE, SAE) 和 IaaS 之间。

## 功能

RP3 的核心功能包括：

* 用户系统
* 工单系统
* 管理员面板

其他功能均以插件实现，包括 SSH, Nginx, PHP-FPM, MySQL, ShadowSocks 等等。

## 使用

    make install    # 安装依赖
    make run        # 直接运行
    make test       # 运行测试
    make build      # 生成 .js
    make clean      # 删除生成的 .js
    make start      # 以 pm2 启动
    make restart    # 重启 pm2 进程
    make stop       # 停止 pm2 进程

## 技术构成

* 前端：Bootstrap3, jQuery, Jade, Less
* 后端：Express, Coffee
* 数据库：MongoDB, redis
* 操作系统支持：Ubuntu 14.04
