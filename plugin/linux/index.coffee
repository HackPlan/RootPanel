service = require './service'
monitor = require './monitor'

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

monitor.run()
