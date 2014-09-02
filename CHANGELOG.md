## v0.7.1(2014.9.2)
有关 ShadowSocks 的漏洞修复，以及从 v0.6.0 升级的迁移脚本。

9 commits, 15 changed files with 183 additions and 42 deletions, by 1 contributors: jysperm.

## v0.7.0(2014.8.31)
用于 2014.8.31，GreenShadow 上线，数据库升级脚本将于 v0.7.1 提供。

* (新增) 数据库升级迁移脚本，兑换代码生成脚本
* (新增) 工单邮件提醒
* (新增) 完成了 ShadowSocks 插件
* (改进) 将 RP 主机的主页独立为了插件
* (改进) 改进扣费机制，改进插件机制
* (改进) 改用 supervisor 运行，弃用 Makefile, 更新 README, 新增配置文件示例

39 commits, 82 changed files with 1110 additions and 440 deletions, by 1 contributors: jysperm.

## v0.6.0(2014.8.11)
用于 2014.8.11, 新版 jp1.rpvhost.net 上线，没有不兼容的数据库更新。

* (新增) 全局启动脚本，文件权限修复工具
* (新增) 修改帐号 QQ, 密码，邮箱
* (新增) 帐号安全事件记录
* (新增) 兑换代码
* (新增) 管理员面板：删除账户
* (改进) 在 Token 中记录 IP, UA, 和最后使用时间。

18 commits, 27 changed files with 366 additions and 29 deletions, by 1 contributors: jysperm.

## v0.5.0(2014.8.7)
用于 2014.8.7, 新版 us1.rpvhost.net 上线。

* (改进) 在面板磁盘占用中记入数据库体积
* (改进) 细化结算机制

11 commits, 13 changed files with 202 additions and 114 deletions, by 1 contributors: jysperm.

## v0.4.0 (2014.7.31)
用于 2014.7.31 的第四次测试，不提供从 v0.3.0 的迁移脚本。

* (新增) 管理员面板新增：站点列表，禁用站点，工单列表
* (新增) 服务器状态监视器
* (新增) 支持了磁盘空间限制和监控
* (改进) 新增了有关部署 Ghost, Typecho 的文档
* (改进) 将插件的前端文件移动至插件目录
* (废弃) 删除了工单类型的设计

24 commits, 74 changed files with 1,274 additions and 594 deletions, by 1 contributors: jysperm.

## v0.3.0 (2014.7.26)
用于 2014.7.26 的第三次测试，不提供从 v0.2.0 的迁移脚本。

* (新增) 支持了 uwsgi, proxy 等 Nginx 指令
* (新增) 实现了 MongoDB 插件
* (新增) 实现了 Nginx 向导模式
* (新增) 实现了 Redis 插件
* (改进) 重写了全部前端逻辑
* (改进) 测试了资源限制并在面板上显示

25 commits, 54 changed files with 882 additions and 269 deletions, by 1 contributors: jysperm.

## v0.2.0 (2014.7.21)
用于 2014.7.21 的第二次测试，不提供从 v0.1.0 的迁移脚本。

* (新增) 支持了比特币支付
* (新增) 添加了充值页面、付款日志和扣费日志
* (新增) 添加了用户手册页面、服务支持页面和首页
* (新增) 管理员页面和功能
* (新增) Linux 插件和资源监控
* (新增) Memcached 插件
* (新增) MySQL 插件
* (新增) PHP-FPM 插件
* (新增) Nginx 插件，尚只支持 PHP-FPM 站点
* (改进) 细化了安装教程，补充了用户手册
* (改进) 优化了路由绑定，重构了 Model 模型
* (废弃) 删除了原 API 测试

168 commits, 146 changed files with 2,761 additions and 1,459 deletions, by 2 contributors: jysperm, yudong.

## v0.1.0 (2014.5.18)

第一个版本，用于 2014.5.18 的第一次公开测试。

* 帐号注册，登录
* 订阅和退订套餐
* SSH 插件
