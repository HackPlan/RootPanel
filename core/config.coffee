module.exports =
  web:
    port: 3000

  account:
    cookie_time: 30 * 24 * 3600 * 1000

  i18n:
    defaultLanguage: 'zh_CN'
    availableLanguage: ['zh_CN']

  ticket:
    availableType: [
      'linux', 'nodejs', 'php', 'python', 'rootpanel'
    ]

  plans:
    all:
      service: ['memcached', 'mongodb', 'mysql', 'nginx', 'phpfpm', 'pptp', 'shadowsocks', 'ssh']
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
