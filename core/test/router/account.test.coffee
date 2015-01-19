describe.skip 'router/account', ->
  agent = null
  utils = null
  csrf_token = null

  account_id = null
  username = null
  email = null
  password = null

  before ->
    {utils} = app
    agent = supertest.agent app.express

  after ->
    namespace.accountRouter =
      account_id: account_id
      csrf_token: csrf_token
      agent: agent

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
      created_objects.accounts.push ObjectId account_id
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

  it 'POST register with invalid email', (done) ->
    agent.post '/account/register'
    .send
      csrf_token: csrf_token
      username: "test#{utils.randomString(20).toLowerCase()}"
      email: "@gmail.com"
      password: password
    .expect 400
    .end (err, res) ->
      res.body.error.should.be.equal 'invalid_email'
      done err

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

  it 'GET session_info when logged', (done) ->
    agent.get '/account/session_info'
    .expect 200
    .end (err, res) ->
      res.body.csrf_token.should.be.exist
      res.body.username.should.be.equal username
      res.body.preferences.should.be.a 'object'
      done err

  it 'POST logout', (done) ->
    agent.post '/account/logout'
    .send
      csrf_token: csrf_token
    .expect 200
    .expect 'set-cookie', /token=;/
    .end done

  it 'POST login with email', (done) ->
    agent.post '/account/login'
    .send
      csrf_token: csrf_token
      username: email.toLowerCase()
      password: password
    .expect 200
    .expect 'set-cookie', /token=/
    .end (err, res) ->
      res.body.id.should.be.equal account_id
      res.body.token.should.be.exist
      done err

  it 'POST login with username does not exist', (done) ->
    agent.post '/account/login'
    .send
      csrf_token: csrf_token
      username: 'username_not_exist'
      password: password
    .expect 400
    .end (err, res) ->
      res.body.error.should.be.equal 'wrong_password'
      expect(res.body.token).to.not.exist
      done err

  it 'POST login with invalid password', (done) ->
    agent.post '/account/login'
    .send
      csrf_token: csrf_token
      username: username
      password: 'invalid password'
    .expect 400
    .end (err, res) ->
      res.body.error.should.be.equal 'wrong_password'
      expect(res.body.token).to.not.exist
      done err

  it 'GET preferences', (done) ->
    agent.get '/account/preferences'
    .expect 200
    .end done

  it 'POST update_password', (done) ->
    new_password = utils.randomString 20

    agent.post '/account/update_password'
    .send
      csrf_token: csrf_token
      original_password: password
      password: new_password
    .expect 200
    .end (err) ->
      password = new_password
      done err

  it 'POST update_email', (done) ->
    email = "#{utils.randomString 20}@gmail.com"

    agent.post '/account/update_email'
    .send
      csrf_token: csrf_token
      password: password
      email: email
    .expect 200
    .end done

  it 'POST update_email with invalid password'

  it 'POST update_preferences', (done) ->
    agent.post '/account/update_preferences'
    .send
      csrf_token: csrf_token
      language: 'en'
    .expect 200
    .end done

  it 'POST update_preferences with invalid key'
