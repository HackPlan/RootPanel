module.exports =
  web:
    t_name: 'plugins.rpvhost.site_name'
    url: 'http://rpvhost.net'
    listen: '/home/rpadmin/rootpanel.sock'
    google_analytics_id: 'UA-49193300-2'

  account:
    cookie_time: 30 * 24 * 3600 * 1000

  i18n:
    available_language: ['zh_CN', 'en']
    default_language: 'zh_CN'
    default_timezone: 'Asia/Shanghai'

  plugin:
    available_extensions: ['rpvhost', 'bitcoin', 'wiki']
    available_services: ['ssh', 'linux']

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

      services: []
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

  plugins:
    bitcoin:
      coinbase_api_key: 'coinbase-simple-api-key'

    rpvhost:
      taobao_item_id: '38370649858'
