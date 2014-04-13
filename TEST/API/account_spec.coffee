frisby = require 'frisby'

config = require '../../core/config'

baseUrl = "http://127.0.0.1:#{config.web.port}"

frisby.create '/account/signup'
  .post "#{baseUrl}/account/signup/",
    username: 'test'
    email: 'test@jysperm.me'
    passwd: 'password'
  .expectStatus 200
  .expectJSONTypes
    id: String
  .toss()
