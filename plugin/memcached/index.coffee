action = require './action'
service = require './service'

module.exports =
  name: 'memcached'
  type: 'service'

  action: action
  service: service

  switch: true
  switch_status: service.switch_status
