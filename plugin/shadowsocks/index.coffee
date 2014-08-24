service = require './service'
action = require './action'

module.exports =
  name: 'shadowsocks'
  type: 'service'

  action: action
  service: service

  layout:
    style: '/style/layout.css'

  panel:
    widget: service.widget
    script: '/script/panel.js'
    style: '/style/panel.css'

service.monitoring()
setInterval service.monitoring, config.plugins.shadowsocks.monitor_cycle
