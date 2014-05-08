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

    shadowsocks:
      price: 8
      t_name: 'ShadowSocks'
      t_service: '仅 ShadowSocks'
      t_resources: '流量: 100GB'
      service: ['shadowsocks']
      resources:
        transfer: 100

  db:
    type: 'mongo'
    server: 'localhost'
    name: 'RootPanel'
    user: 'rpadmin'
    passwd: 'passwd'
