frisby = require 'frisby'

config = require '../../core/config'

baseUrl = "http://127.0.0.1:#{config.web.port}"

frisby.globalSetup
  request:
    headers:
      'x-token': 'token'
