service = require './service'
monitor = require './monitor'

{pluggable} = app

app.view_hook.menu_bar.push
  href: '/public/monitor/'
  html: '服务器状态'

module.exports =
  name: 'linux'
  type: 'service'

  service: service

  panel:
    widget: service.widget
    style:'/style/panel.css'

pluggable.account.username_filter.push (account, callback) ->
  monitor.loadPasswd (passwd_cache) ->
    if req.body.username in _.values(passwd_cache)
      return callback false

    callback true

monitor.run()
