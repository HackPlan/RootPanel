module.exports =
  web:
    t_name: 'plugins.rpvhost.greenshadow'
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
    available_plugins: [
      'bitcoin', 'wiki', 'rpvhost', 'linux', 'supervisor', 'shadowsocks'
    ]

  billing:
    currency: 'CNY'

    force_freeze:
      when_balance_below: 0
      when_arrears_above: 0

    billing_cycle: 10 * 60 * 1000

  plans:
    shadowsocks:
      t_name: 'plugins.rpvhost.plans.shadowsocks.name'
      t_description: 'plugins.rpvhost.plans.shadowsocks.description'

      available_components:
        shadowsocks:
          limit: 1
          default: ->

      resource_limit: {}

      billing_trigger:
        'shadowsocks.traffic':
          bucket: 100 * 1000 * 1000
          price: 0.06

  ssh:
    id_key: '/home/rpadmin/.ssh/id_rsa'

  nodes:
    master:
      host: 'localhost'
      master: true
      available_components: []

  mongodb:
    user: 'rpadmin'
    password: 'password'
    host: 'localhost'
    name: 'RootPanel'
    test: 'RootPanel-test'

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

    wiki:
      disable_default_wiki: true

    rpvhost:
      index_page: false
      green_style: true
      taobao_item_id: '41040606505'

    shadowsocks:
      available_ciphers: ['aes-256-cfb', 'rc4-md5']

      billing_bucket: 100 * 1000 * 1000
      monitor_cycle: 5 * 60 * 1000
      price_bucket: 0.06
