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

  it 'GET preferences'

  it 'GET preferences with not logged', (done) ->
    client.get 'preferences',
      response_json: false
      expect_status_code: 302
    , ->
      @res.headers.location.should.be.equal '/account/login/'
      done()

  it 'POST register'

  it 'POST login'

  it 'POST logout'

  it 'POST update_password'

  it 'POST update_email'

  it 'POST update_preferences'

  it 'GET coupon_info'

  it 'POST apply_coupon'
