action = require './action'
service = require './service'

module.exports =
  name: 'nginx'
  type: 'service'

  action: action
  service: service

  panel:
    widget: service.widget
    script: '/script/panel.js'
    style:'/style/panel.css'
