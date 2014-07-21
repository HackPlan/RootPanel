## 安装
首先你需要成功开通了套餐，然后开启 PHP-FPM, 修改 SSH 密码，修改 MySQL 密码。

登录 SSH, 执行以下命令下载 WordPress, 请自行到官网查看最新版本的下载地址：

    wget http://cn.wordpress.org/wordpress-3.9-zh_CN.zip

解压文件：

    unzip wordpress-*.zip

设置文件权限：

    chmod -R 750 wordpress

删除安装包：

    rm wordpress-*.zip

进入 MySQL 控制台(需要输入你的 MySQL 密码):

    mysql -p

(在 MySQL 中) 创建数据库(补全你的用户名):

    CREATE DATABASE `<用户名>_wordpress`;

回到面板添加 Nginx 站点(补全你的用户名):

    {
        "listen": 80,
        "server_name": ["<用户名>.rp3.rpvhost.net"],
        "index": [
            "index.php",
            "index.html"
        ],
        "root": "/home/<用户名>/wordpress",
        "location": {
            "/": {
                "try_files": ["$uri", "$uri/", "/index.php?$args"]
            },
            "~ \\.php$": {
                "fastcgi_pass": "unix:///home/<用户名>/phpfpm.sock",
                "fastcgi_index": ["index.php"],
                "include": "fastcgi_params"
            }
        }
    }

访问 `<用户名>.rp3.rpvhost.net`, 点击 `创建配置文件`, 正确填写数据库名、数据库用户名(你的用户名)、密码，然后下一个页面中填写你的博客的基本信息，即可完成安装。
