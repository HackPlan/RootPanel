module.exports =
  web:
    t_name: 'RootPanel'
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
    available_plugins: []

  billing:
    currency: 'CNY'

    force_freeze:
      when_balance_below: 0
      when_arrears_above: 0

    billing_cycle: 10 * 60 * 1000

  plans:
    sample:
      t_name: 'plans.sample.name'
      t_description: 'plans.sample.description'

      available_components: {}
      resource_limit: {}

      billing:
        time:
          interval: 24 * 3600 * 1000
          price: 10 / 30
          prepaid: true

    test:
      t_name: 'plans.test.name'
      t_description: 'plans.test.description'

      available_components: {}
      resource_limit: {}

      billing: {}

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

  plugins: {}
