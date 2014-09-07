module.exports =
  web:
    name: 'RootPanel'
    url: 'http://rpvhost.net'
    listen: '/home/rpadmin/rootpanel.sock'
    google_analytics_id: 'UA-49193300-2'

  account:
    cookie_time: 30 * 24 * 3600 * 1000

  i18n:
    available_language: ['zh_CN']
    default_language: 'zh_CN'
    default_timezone: 'Asia/Shanghai'

  plugin:
    available_extensions: []
    available_services: []

  billing:
    currency: 'CNY'

    taobao_item_id: '41040606505'

    force_unsubscribe:
      when_balance_below: 0
      when_arrears_above: 0

    cyclical_billing: 3600 * 1000
    daily_billing_cycle: 24 * 3600 * 1000

  plans:
    sample:
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

  plugins: {}
