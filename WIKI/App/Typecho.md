## 安装
首先你需要成功开通了套餐，然后开启 PHP-FPM, 修改 SSH 密码，MySQL 密码。

登录 SSH, 执行以下命令下载 Typecho, 请自行到官网查看最新版本的下载地址：

    wget https://github.com/typecho/typecho/releases/download/v0.9-13.12.12-release/0.9.13.12.12.-release.tar.gz
    
解压文件：

    tar zxvf *-release.tar.gz
    mv build typecho
    
设置文件权限：

    chmod -R 750 typecho

删除安装包：

    rm *-release.tar.gz

进入 MySQL 控制台(需要输入你的 MySQL 密码):

    mysql -p

(在 MySQL 中) 创建数据库(补全你的用户名):

    CREATE DATABASE `<用户名>_typecho`;
    
回到面板添加 Nginx 站点(补全你的用户名):

* 域名：`<用户名>.rp3.rpvhost.net`
* 类型：fastcgi (PHP)
* 根目录：`/home/<用户名>/typecho`

访问 `<用户名>.rp3.rpvhost.net`, 点击 `下一步`, 正确填写数据库名、数据库用户名(你的用户名)、密码，然后下一个页面中填写你的博客的基本信息，即可完成安装。

## 永久链接
在启用「永久链接」功能时，Typecho 会提示「重写功能检测失败, 请检查你的服务器设置」，请无视该提示，直接「如果你仍然想启用此功能, 请点击这里」即可。
