module.exports =
  web:
    t_name: 'plugins.rpvhost.site_name'
    url: 'http://greenshadow.net'
    listen: '/home/rpadmin/rootpanel.sock'
    repo: 'jysperm/RootPanel'
    google_analytics_id: ''

  account:
    cookie_time: 30 * 24 * 3600 * 1000

  i18n:
    available_language: ['zh_CN', 'en']
    default_language: 'zh_CN'
    default_timezone: 'Asia/Shanghai'

  plugin:
    available_extensions: ['bitcoin', 'wiki', 'rpvhost']
    available_services: ['linux', 'supervisor', 'shadowsocks']

  billing:
    currency: 'CNY'

    force_freeze:
      when_balance_below: 0
      when_arrears_above: 0

    billing_cycle: 10 * 60 * 1000

  plans:
    all:
      t_name: 'plugins.rpvhost.plans.shadowsocks.name'
      t_description: 'plugins.rpvhost.plans.shadowsocks.description'

      billing_by_usage:
        auto_leave: 14 * 24 * 3600 * 1000

      services: ['shadowsocks']

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
    linux:
      monitor_cycle: null

    bitcoin:
      coinbase_api_key: 'coinbase-simple-api-key'

    rpvhost:
      index_page: false
      taobao_item_id: '41040606505'

    shadowsocks:
      green_style: true

      available_ciphers: ['aes-256-cfb', 'rc4-md5']

      billing_bucket: 100 * 1024 * 1024
      monitor_cycle: 5 * 60 * 1000
      price_bucket: 0.06
