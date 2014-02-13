module.exports =
  web:
    port: 3000

  i18n:
    defaultLanguage: 'zh_CN'
    availableLanguage: ['zh_CN']

  db:
    type: 'mongo'
    server: '/home/rpadmin/mongod.sock'
    user: 'rpadmin'
    passwd: 'passwd'
