action = require './action'
service = require './service'

module.exports =
  name: 'phpfpm'
  type: 'service'

  action: action
  service: service

  panel_widgets: [
    service.widget
  ]
