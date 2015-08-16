module.exports =
  web:
    name: 'RootPanel'
    url: 'http://rp.rpvhost.net'
    listen: '/tmp/rootpanel.sock'
    repo: 'jysperm/RootPanel'
    google_analytics_id: ''
    cookie_time: 30 * 24 * 3600 * 1000

  i18n:
    default_language: 'zh-CN'
    default_timezone: 'Asia/Shanghai'

  plugins:
    'built-in':
      enable: true
    linux:
      enable: true

  server:
    ssh:
      id_key: './.ssh/id_rsa'

    servers:
      master:
        host: 'localhost'
        master: true
        available_components: []

  billing:
    currency: 'CNY'

    freeze_conditions:
      balance_below: 0
      arrears_above: 0

    plans:
      sample:
        name: 'plans.sample.name'
        description: 'plans.sample.description'

        components: {}

        billing:
          time:
            interval: 24 * 3600 * 1000
            price: 10 / 30
            prepaid: true

  mongodb:
    host: 'localhost'
    name: 'RootPanel'

  redis:
    host: '127.0.0.1'
    port: 6379

  email:
    from: 'robot@rpvhost.net'
    reply_to: 'admins@rpvhost.net'

    account:
      service: 'Postmark'
      auth:
        user: 'postmark-api-token'
        pass: 'postmark-api-token'
