module.exports =
  web:
    port: 3000

  admin:
    username: ['jysperm']

  account:
    cookie_time: 30 * 24 * 3600 * 1000

  i18n:
    defaultLanguage: 'zh_CN'
    availableLanguage: ['zh_CN']

  ticket:
    availableType: [
      'linux', 'nodejs', 'php', 'python', 'rootpanel'
    ]

  plugin:
    availablePlugin: ['shadowsocks']

  plans:
    all:
      price: 8
      t_name: '所有服务(默认)'
      t_service: '支持所有服务'
      t_resources: '磁盘: 520MB, 内存: 27MB, 流量: 37GB'
      service: ['memcached', 'mongodb', 'mysql', 'nginx', 'phpfpm', 'pptp', 'shadowsocks', 'ssh']
      resources:
        storage: 520
        transfer: 39
        memory: 27

    ssh:
      price: 8
      t_name: 'SSH'
      t_service: '仅 SSH'
      t_resources: '前期测试用'
      service: ['ssh']
      resources:
        storage: 520
        transfer: 39
        memory: 27

  db:
    type: 'mongo'
    server: 'localhost'
    name: 'RootPanel'
    user: 'rpadmin'
    passwd: 'passwd'
