module.exports =
  web:
    name: 'GreenShadow'
    url: 'http://ss.rpvhost.net'
    listen: '/home/rpadmin/rootpanel.sock'
    google_analytics_id: 'UA-49193300-2'

  account:
    cookie_time: 30 * 24 * 3600 * 1000

  i18n:
    available_language: ['zh_CN']
    default_language: 'zh_CN'
    default_timezone: 'Asia/Shanghai'

  plugin:
    available_extensions: ['rpvhost', 'wiki', 'bitcoin']
    available_services: ['shadowsocks']

  billing:
    currency: 'CNY'

    taobao_item_id: '38370649858'

    force_unsubscribe:
      when_balance_below: 0
      when_arrears_above: 0

    cyclical_billing: 3600 * 1000
    daily_billing_cycle: 24 * 3600 * 1000

  plans:
    shadowsocks:
      t_name: 'ShadowSocks'
      t_service: '按量付费'
      t_resources: '0.6 CNY / G'
      services: ['shadowsocks']
      resources: {}

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

  redis_password: 'password'

  email:
    send_from: 'robot@rpvhost.net'

    account:
      service: 'Postmark'
      auth:
        user: 'postmark-api-token'
        pass: 'postmark-api-token'

  bitcoin:
    coinbase_api_key: 'coinbase-simple-api-key'

  plugins:
    rpvhost:
      index_page: false

    shadowsocks:
      price_bucket: 0.06
      monitor_cycle: 5 * 60 * 1000
      billing_bucket: 100 * 1024 * 1024

    linux:
      monitor_cycle: 30 * 1000

    mysql:
      connection:
        host: 'localhost'
        user: 'rpadmin'
        password: 'password'
