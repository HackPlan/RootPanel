path = require 'path'

{pluggable} = app
{renderAccount} = app.middleware

module.exports = exports = pluggable.createHelpers module.exports,
  name: 'rpvhost'
  type: 'extension'

exports.registerHook 'view.layout.menu_bar',
  href: '//blog.rpvhost.net'
  target: '_blank'
  body: '官方博客'

app.get '/', renderAccount, (req, res) ->
  res.render path.join(__dirname, './view/index')
