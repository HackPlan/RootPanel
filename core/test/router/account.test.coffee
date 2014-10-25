describe 'router/account', ->
  agent = null
  utils = null
  csrf_token = null

  account_id = null
  username = null
  email = null
  password = null

  before ->
    require '../../../app'
    {utils} = app
    agent = supertest.agent app.express

  it 'GET login', (done) ->
    agent.get '/account/login'
    .expect 200
    .end done

  it 'GET preferences with not logged', (done) ->
    agent.get '/account/preferences'
    .redirects 0
    .expect 302
    .expect 'location', '/account/login/'
    .end done

  it 'GET register', (done) ->
    agent.get '/account/register'
    .expect 200
    .end done

  it 'GET session_info', (done) ->
    agent.get '/account/session_info'
    .expect 200
    .end (err, res) ->
      res.body.csrf_token.should.be.exist
      csrf_token = res.body.csrf_token
      done err

  it 'POST register', (done) ->
    username = "test#{utils.randomString(20).toLowerCase()}"
    email = "#{utils.randomString 20}@gmail.com"
    password = utils.randomString 20

    agent.post '/account/register'
    .send
      csrf_token: csrf_token
      username: username
      email: email
      password: password
    .expect 200
    .expect 'set-cookie', /token=/
    .end (err, res) ->
      res.body.id.should.have.length 24
      account_id = res.body.id
      done err

  it 'POST register with existed username', (done) ->
    agent.post '/account/register'
    .send
      csrf_token: csrf_token
      username: username
      email: "#{utils.randomString 20}@gmail.com"
      password: password
    .expect 400
    .end (err, res) ->
      res.body.error.should.be.equal 'username_exist'
      done err

  it 'POST register with invalid email'

  it 'POST login', (done) ->
    agent.post '/account/login'
    .send
      csrf_token: csrf_token
      username: username
      password: password
    .expect 200
    .expect 'set-cookie', /token=/
    .end (err, res) ->
      res.body.id.should.be.equal account_id
      res.body.token.should.be.exist
      done err

  it 'POST login with email'

  it 'POST login with username does not exist'

  it 'POST login with invalid password'

  it 'GET preferences'

  it 'POST logout'

  it 'POST update_password'

  it 'POST update_email'

  it 'POST update_preferences'

  it 'GET coupon_info'

  it 'POST apply_coupon'
