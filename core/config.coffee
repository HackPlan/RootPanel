module.exports =
  web:
    port: 3000

  account:
    cookieTime: 30 * 24 * 3600 * 1000

  i18n:
    defaultLanguage: 'zh_CN'
    availableLanguage: ['zh_CN']

  ticket:
    availableType: [
      'linux', 'nodejs', 'php', 'python', 'rootpanel'
    ]

  db:
    type: 'mongo'
    server: 'localhost'
    name: 'RootPanel'
    user: 'rpadmin'
    passwd: 'passwd'
