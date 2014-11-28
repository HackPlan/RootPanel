module.exports =
  web:
    t_name: 'plugins.rpvhost.'
    url: 'http://rp.rpvhost.net'
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
      'bitcoin', 'wiki', 'rpvhost','linux', 'supervisor', 'ssh'
    ]

  billing:
    currency: 'CNY'

    force_freeze:
      when_balance_below: 0
      when_arrears_above: 0

    billing_cycle: 10 * 60 * 1000

  plans:
    all:
      t_name: 'plugins.rpvhost.plans.all.name'
      t_description: 'plugins.rpvhost.plans.all.description'

      available_components:
        supervisor: {}
        linux:
          limit: 1
          default: (account) ->
            return username: account.username
        ssh:
          limit:1
          default: (account) ->
            return username: account.username

      resource_limit:
        cpu: 144
        storage: 520
        transfer: 39
        memory: 27

      billing:
        time:
          interval: 24 * 3600 * 1000
          price: 10 / 30
          prepaid: true

  nodes:
    master:
      ip: 'localhost'
      master: true
      available_components: []

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
      index_page: true
      taobao_item_id: '38370649858'

    linux:
      monitor_cycle: 30 * 1000
