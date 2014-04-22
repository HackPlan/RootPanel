action = require './action'
service = require './service'
monitor = require './monitor'

module.exports =
  name: 'pptp'
  type: 'service'
  version: '0.1.0'

  action: action
  service: service
  monitor: monitor

  panel_widget:
    content: action.widget

  resources: [
    'transfer'
  ]
