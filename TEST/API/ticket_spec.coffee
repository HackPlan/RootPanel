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

frisby.create '/ticket/reply/'
  .post "#{baseUrl}/ticket/reply/",
    id: '533b0cb894f6c673123e33a4'
    content: 'Reply Content(Markdown)'
  .expectStatus 200
  .expectJSONTypes
    id: String
  .toss()

frisby.create '/ticket/update/'
  .post "#{baseUrl}/ticket/update/",
    id: '533b0cb894f6c673123e33a4'
    type: 'nodejs'
    status: 'closed'
  .expectStatus 200
  .toss()

frisby.create '/ticket/update/'
  .post "#{baseUrl}/ticket/update/",
    id: '533b0cb894f6c673123e33a4'
    attribute:
      public: true
  .expectStatus 200
  .toss()

frisby.create '/ticket/list/'
  .post "#{baseUrl}/ticket/list/",
    status: 'open'
  .expectStatus 200
  .expectJSON '*',
    status: 'open'
  .expectJSONTypes '*',
    id: String
    title: String
    type: String
    updated_at: String
  .toss()
