action = require './action'
service = require './service'
monitor = require './monitor'

module.exports =
  name: 'mysql'
  type: 'service'
  version: '0.1.0'

  action: action
  service: service
  monitor: monitor

  static: './static'

  resources: [
    'storage', 'cpu', 'memory'
  ]
