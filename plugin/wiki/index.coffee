{pluggable} = app
{renderAccount} = app.middleware

wiki = require './wiki'

module.exports =
  name: 'wiki'
  type: 'extension'

pluggable.registerHook 'view.layout.menu_bar', module.exports,
  href: '/wiki/'
  body: '用户手册'

app.use '/wiki', renderAccount, wiki.router
