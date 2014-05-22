action = require './action'
service = require './service'
monitor = require './monitor'

module.exports =
  name: 'ssh'
  type: 'service'
  version: '0.1.0'

  action: action
  service: service

  panel_widgets: [
    service.widget
  ]
