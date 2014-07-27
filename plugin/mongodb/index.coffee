app.plugins.mongodb = {}

action = require './action'
service = require './service'

module.exports =
  name: 'mongodb'
  type: 'service'

  action: action
  service: service

  panel:
    widget: service.widget
    script: '/script/panel.js'
