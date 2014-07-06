module.exports =
  web:
    url: 'http://rp3.rpvhost.net'
    port: 3000

  debug:
    mock_test: false

  admin:
    username: ['jysperm']

  account:
    invalid_username: [
      'root', 'daemon', 'bin', 'sys', 'sync', 'games', 'man', 'lp', 'mail', 'colord', 'nobody',
      'syslog', 'sshd', 'ntp', 'memcache', 'mongodb', 'rpadmin', 'postfix', 'libuuid', 'mysql',
      'news', 'uucp', 'proxy', 'www-data', 'backup', 'list', 'irc', 'gnats', 'messagebus'
    ]
    cookie_time: 30 * 24 * 3600 * 1000

  i18n:
    defaultLanguage: 'zh_CN'
    availableLanguage: ['zh_CN']

  ticket:
    availableType: [
      'linux', 'nodejs', 'php', 'python', 'rootpanel'
    ]

  plugin:
    availablePlugin: ['linux', 'ssh', 'phpfpm', 'mysql', 'nginx']

  plans:
    all:
      price: 8
      t_name: '所有服务(默认)'
      t_service: '支持所有服务'
      t_resources: '磁盘: 520MB, 内存: 27MB, 流量: 37GB'
      services: ['linux', 'ssh', 'phpfpm', 'mysql', 'nginx']
      resources:
        cpu: 144
        storage: 520
        transfer: 39
        memory: 27

  mongodb: 'mongodb://localhost/RootPanel'

  bitcoin:
    forward_to: '1FjhhWrzAvb9YD4tVdbE6wrSoHSwxMJoWe'
    confirmations: 1

  plugins:
    linux:
      cycle: 30 * 1000

    mysql:
      connection:
        host: 'localhost'
        user: 'rpadmin'
        password: 'passwd'
