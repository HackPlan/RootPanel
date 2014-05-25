action = require './action'
service = require './service'

module.exports =
  name: 'mysql'
  type: 'service'

  action: action
  service: service

  panel_widgets: [
    service.widget
  ]
