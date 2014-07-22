module.exports =
  web:
    url: 'http://rp3.rpvhost.net'
    listen: 3000

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
    availablePlugin: ['linux', 'ssh', 'phpfpm', 'mysql', 'nginx', 'memcached', 'mongodb']

  plans:
    all:
      price: 10
      t_name: '所有服务(默认)'
      t_service: '支持所有服务'
      t_resources: '磁盘: 520MB, 内存: 27MB, 流量: 37GB'
      services: ['linux', 'ssh', 'phpfpm', 'mysql', 'nginx', 'memcached', 'mongodb']
      resources:
        cpu: 144
        storage: 520
        transfer: 39
        memory: 27

  mongodb: 'mongodb://rpadmin:password@localhost/RootPanel'
  redis_password: 'password'

  bitcoin:
    coinbase_api_key: null

  plugins:
    linux:
      monitor_cycle: 30 * 1000

    mysql:
      connection:
        host: 'localhost'
        user: 'rpadmin'
        password: 'password'
