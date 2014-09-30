{pluggable} = app
{renderAccount} = app.middleware

wiki = require './wiki'

module.exports = pluggable.createHelpers exports =
  name: 'wiki'
  type: 'extension'

exports.registerHook 'view.layout.menu_bar',
  href: '/wiki/'
  body: '用户手册'

app.use '/wiki', renderAccount, wiki.router
