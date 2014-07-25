action = require './action'
service = require './service'

module.exports =
  name: 'nginx'
  type: 'service'

  action: action
  service: service

  panel_widgets: [
    service.widget
  ]

  panel_script: [
    '/static/script/panel.js'
  ]
