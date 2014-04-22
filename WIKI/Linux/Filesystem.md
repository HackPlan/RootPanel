## 文件系统

### 用户目录
在 RP 主机上，你能够修改的文件仅限于你的 home 目录，即 `/home/user`.

### Unix Socket
在 RP 主机上，基于 TCP 端口的网络是不安全的，意味着其他用户也可以访问你建立的服务(如 Memcached, MongoDB).  
推荐使用 Unix Socket 来创建服务，因为 Unix Socket 基于文件系统的权限，你可以灵活地设置它的权限，阻止其他用户访问。
