module.exports =
  web:
    url: 'http://ss.rpvhost.net'
    listen: '/home/rpadmin/rootpanel.sock'
    google_analytics_id: 'UA-49193300-2'

  account:
    cookie_time: 30 * 24 * 3600 * 1000

  i18n:
    defaultLanguage: 'zh_CN'
    availableLanguage: ['zh_CN']

  plugin:
    available_extensions: ['rpvhost']
    available_services: ['shadowsocks']

  billing:
    force_unsubscribe:
      when_balance_below: 0
      when_arrears_above: 0

    cyclical_billing: 3600 * 1000
    daily_billing_cycle: 24 * 3600 * 1000

  plans:
    shadowsocks:
      t_name: 'ShadowSocks 按量付费'
      t_service: 'ShadowSocks'
      t_resources: '0.6 CNY / G'
      services: ['shadowsocks']
      resources: {}

  nodes:
    ss:
      domain: 'ss.rpvhost.net'
      location: 'Linode Fremont, CA, USA'
      readme: 'ShadowSocks Only'

  mongodb:
    user: 'rpadmin'
    password: 'password'
    host: 'localhost'
    name: 'RootPanel'

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
