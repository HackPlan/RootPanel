path = require 'path'

{pluggable} = app
{renderAccount} = app.middleware

module.exports =
  name: 'rpvhost'
  type: 'extension'

pluggable.registerHook 'view.layout.menu_bar', module.exports,
  href: '//blog.rpvhost.net'
  target: '_blank'
  body: '官方博客'

app.get '/', renderAccount, (req, res) ->
  res.render path.join(__dirname, './view/index')
