service = require './service'

module.exports =
  name: 'linux'
  type: 'service'

  service: service

  panel_widgets: [
    service.widget
  ]
