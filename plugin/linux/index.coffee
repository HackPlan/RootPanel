service = require './service'
monitor = require './monitor'

module.exports =
  name: 'linux'
  type: 'service'

  service: service

  panel_widgets: [
    service.widget
  ]

monitor.run()
