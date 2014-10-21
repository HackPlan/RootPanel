client.defaultOptions
  uri_prefix: '/account/'

describe 'router/account', ->
  it 'GET register', (done) ->
    client.get 'register',
      response_json: false
    , ->
      done()

  it 'GET login', (done) ->
    client.get 'login',
      response_json: false
    , ->
      done()

  it 'GET preferences', (done) ->
    client.get 'preferences',
      response_json: false
    , ->
      done()
