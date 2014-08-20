action = require './action'

app.view_hook.menu_bar.push
  href: '//blog.rpvhost.net'
  target: '_blank'
  html: '官方博客'

module.exports =
  name: 'rpvhost'
  type: 'extension'
