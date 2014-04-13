frisby = require 'frisby'

config = require '../../core/config'

baseUrl = "http://127.0.0.1:#{config.web.port}"

frisby.globalSetup
  request:
    headers:
      'x-token': 'token'

frisby.create '/ticket/create/'
  .post "#{baseUrl}/ticket/create/",
    title: 'Ticket Title'
    content: 'Ticket Content(Markdown)'
    type: 'linux'
  .expectStatus 200
  .expectJSONTypes
    id: String
  .toss()

frisby.create '/ticket/create/ invalid_type'
  .post "#{baseUrl}/ticket/create/",
    title: 'Ticket Title'
    content: 'Ticket Content(Markdown)'
    type: 'type_not_exist'
  .expectStatus 400
  .expectJSON
    error: 'invalid_type'
  .toss()

frisby.create '/ticket/create/'
  .post "#{baseUrl}/ticket/create/",
    title: 'Ticket Title'
    content: 'Ticket Content(Markdown)'
    type: 'linux'
    members: ['test']
  .expectStatus 200
  .expectJSONTypes
    id: String
  .toss()
