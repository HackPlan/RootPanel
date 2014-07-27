service = require './service'
monitor = require './monitor'

module.exports =
  name: 'linux'
  type: 'service'

  service: service

  panel:
    widget: service.widget
    style:'/style/panel.css'

monitor.run()
