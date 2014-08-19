service = require './service'
action = require './action'

module.exports =
  name: 'shadowsocks'
  type: 'service'

  action: action
  service: service

  panel:
    widget: service.widget
    script: '/script/panel.js'
