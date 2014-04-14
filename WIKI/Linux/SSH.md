## SSH
在 RP 主机上，每个用户都表现为一个标准的 Linux 帐号，SSH 将是你管理 RP 主机的主要方式，通过 SSH 你可以在 RP 主机上执行命令，运行程序，管理文件。

### SSH 客户端

* Linux 和 OS X 均内置了 ssh 客户端，直接在终端运行 `ssh` 命令即可。
* Windows 推荐下面两款客户端

    * [PuTTY](http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html)

        开源，默认无中文支持。

    * [Xshell](http://www.netsarang.com/download/down_xsh.html)

        对个人用户免费，有中文 UI.

### 登录到服务器

服务器即你所注册的节点的域名，如 `jp1.rpvhost.net`.

端口除了标准的 22 端口，还有 822, 722 两个备用端口可用(用于某些极端网络情况).

用户名即你在 RP 主机的用户名。

SSH 密码需要在 RP 主机的 Web 管理面板上单独设置。

### 设置公钥登录

可以将你的公钥上传到 `/home/user/.ssh/authorized_keys`, 以实现通过公钥验证来登录到服务器。

如果上传公钥后仍出现需要密码的情况，请确认相关文件的权限设置无误。

通过在登录时，向 ssh 传递 `-vvT` 参数，可以获得一些帮助信息。
