## 安装
首先你需要成功开通了套餐，修改 SSH 密码。

登录 SSH, 执行以下命令下载 Ghost, 请自行到官网查看最新版本的下载地址：

    wget https://ghost.org/zip/ghost-0.4.2.zip

解压文件：

    unzip ghost-*.zip -d ghost
    
设置文件权限：

    chmod -R 750 ghost
    
删除安装包：

    rm ghost-*.zip
    
安装依赖：

    npm install --production
    
修改配置文件：

    vi ghost/config.js
    
修改 `production.server` 段下：

注释掉：

    // host: '127.0.0.1',
    // port: '2368'
    
添加(补全你的用户名):

    socket: '/home/<用户名>/ghost.sock'
    
启动 Ghost:

    NODE_ENV=production forever start ghost/index.js
    
回到面板添加 Nginx 站点(补全你的用户名):

* 域名：`<用户名>.rp3.rpvhost.net`
* 类型：proxy (反向代理)
* 源地址：`http://unix:/home/<用户名>/ghost.sock:/`
