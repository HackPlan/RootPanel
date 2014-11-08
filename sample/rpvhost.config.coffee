module.exports =
  web:
    t_name: 'plugins.rpvhost.site_name'
    url: 'http://rp.rpvhost.net'
    listen: '/home/rpadmin/rootpanel.sock'
    google_analytics_id: ''

  account:
    cookie_time: 30 * 24 * 3600 * 1000

  i18n:
    available_language: ['zh_CN', 'en']
    default_language: 'zh_CN'
    default_timezone: 'Asia/Shanghai'

  plugin:
    available_extensions: ['bitcoin', 'wiki', 'rpvhost']
    available_services: ['linux', 'supervisor', 'ssh']

  billing:
    currency: 'CNY'

    force_freeze:
      when_balance_below: 0
      when_arrears_above: 0

    billing_cycle: 10 * 60 * 1000

  plans:
    all:
      t_name: 'plans.all.name'
      t_description: 'plans.all.name.description'

      billing_by_time:
        unit: 24 * 3600 * 1000
        price: 10 / 30

      services: ['supervisor', 'linux', 'ssh']

      resources:
        cpu: 144
        storage: 520
        transfer: 39
        memory: 27

  mongodb:
    user: 'rpadmin'
    password: 'password'
    host: 'localhost'
    name: 'RootPanel'

  redis:
    host: '127.0.0.1'
    port: 6379
    password: 'password'
    prefix: 'RP'

  email:
    send_from: 'robot@rpvhost.net'

    account:
      service: 'Postmark'
      auth:
        user: 'postmark-api-token'
        pass: 'postmark-api-token'

  plugins:
    bitcoin:
      coinbase_api_key: 'coinbase-simple-api-key'

    rpvhost:
      taobao_item_id: '38370649858'

    linux:
      monitor_cycle: 30 * 1000
