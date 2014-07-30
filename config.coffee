module.exports =
  web:
    url: 'http://rp3.rpvhost.net'
    listen: 3000

  account:
    cookie_time: 30 * 24 * 3600 * 1000

  i18n:
    defaultLanguage: 'zh_CN'
    availableLanguage: ['zh_CN']

  plugin:
    availablePlugin: ['linux', 'ssh', 'phpfpm', 'mysql', 'nginx', 'memcached', 'mongodb', 'redis']

  plans:
    all:
      price: 10
      t_name: '所有服务(默认)'
      t_service: '支持所有服务'
      t_resources: '磁盘: 520MB, 内存: 27MB, 流量: 37GB'
      services: ['linux', 'ssh', 'phpfpm', 'mysql', 'nginx', 'memcached', 'mongodb', 'redis']
      resources:
        cpu: 144
        storage: 520
        transfer: 39
        memory: 27

  nodes:
    us1:
      domain: 'us1.rpvhost.net'
      location: 'Linode Fremont, CA, USA'

    jp1:
      domain: 'jp1.rpvhost.net'
      location: 'Linode Tokyo, JP'

    rp3:
      domain: 'rp3.rpvhost.net'
      location: 'Linode Fremont, CA, USA'

  mongodb:
    user: 'rpadmin'
    password: 'password'
    host: 'localhost'
    name: 'RootPanel'

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
