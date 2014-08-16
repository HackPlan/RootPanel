service = require './service'
action = require './action'

module.exports =
  name: 'shadowsocks'
  type: 'service'

  service: service

  panel:
    widget: service.widget
