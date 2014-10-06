action = require './action'
service = require './service'

module.exports =
  name: 'ssh'
  type: 'service'

  dependencies: ['linux']

  action: action
  service: service

  panel:
    widget: service.widget
    script: '/script/panel.js'
