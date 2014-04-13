frisby = require 'frisby'

config = require '../../core/config'

baseUrl = "http://127.0.0.1:#{config.web.port}"

frisby.create '/account/signup/'
  .post "#{baseUrl}/account/signup/",
    username: 'test'
    email: 'test@jysperm.me'
    passwd: 'password'
  .expectStatus 200
  .expectJSONTypes
    id: String
  .toss()

frisby.create '/account/signup email_exist'
  .post "#{baseUrl}/account/signup/",
    username: 'test2'
    email: 'test@jysperm.me'
    passwd: 'password'
  .expectStatus 400
  .expectJSON
    error: 'email_exist'
  .toss()

frisby.create '/account/login/'
  .post "#{baseUrl}/account/login/",
    username: 'test@jysperm.me',
    passwd: 'password'
  .expectStatus 200
  .expectJSONTypes
    id: String
    token: String
  .toss()

frisby.create '/account/login/'
  .post "#{baseUrl}/account/login/",
    username: 'test',
    passwd: 'password'
  .expectStatus 200
  .expectJSONTypes
    id: String
    token: String
  .toss()

frisby.create '/account/logout/'
  .post "#{baseUrl}/account/logout/", {},
    headers:
      'x-token': 'need_be_remove'
  .expectStatus 200
  .toss()

frisby.create '/account/logout/ auth_failed'
  .post "#{baseUrl}/account/logout/", {},
    headers:
      'x-token': 'token_not_exist'
  .expectStatus 400
  .expectJSON
    error: 'auth_failed'
  .toss()
