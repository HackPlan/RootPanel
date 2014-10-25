describe 'router/account', ->
  agent = null

  before ->
    require '../../../app'
    agent = supertest.agent app.express

  it 'GET register', (done) ->
    agent.get '/account/register'
    .expect 200
    .end done

  it 'GET login', (done) ->
    agent.get '/account/login'
    .expect 200
    .end done

  it 'GET preferences'

  it 'GET preferences with not logged', (done) ->
    agent.get '/account/preferences'
    .redirects 0
    .expect 302
    .expect 'location', '/account/login/'
    .end done

  it 'POST register'

  it 'POST login'

  it 'POST logout'

  it 'POST update_password'

  it 'POST update_email'

  it 'POST update_preferences'

  it 'GET coupon_info'

  it 'POST apply_coupon'
