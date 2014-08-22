module.exports =
  web:
    url: 'http://rp3.rpvhost.net'
    listen: 3000
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

  plans:
    shadowsocks:
      t_name: 'ShadowSocks 按量付费'
      t_service: 'ShadowSocks'
      t_resources: '0.6 CNY / G'
      services: ['shadowsocks']
      resources: {}

  nodes:
    us1:
      domain: 'us1.rpvhost.net'
      location: 'Linode Fremont, CA, USA'
      readme: ''

    jp1:
      domain: 'jp1.rpvhost.net'
      location: 'Linode Tokyo, JP'
      readme: ''

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
    coinbase_api_key: null

  plugins:
    rpvhost:
      index_page: false

    linux:
      monitor_cycle: 30 * 1000

    mysql:
      connection:
        host: 'localhost'
        user: 'rpadmin'
        password: 'password'
