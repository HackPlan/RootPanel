describe 'account.register', ->
  agent = null
  csrf_token = null

  account_id = null
  username = null
  password = null
  email = null

  before ->
    agent = supertest.agent app.express

  after (done) ->
    cleanUpByAccount account_id, done

  it 'GET login', (done) ->
    agent.get '/account/login'
    .expect 200
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
      {csrf_token} = res.body
      done err

  it 'POST register', (done) ->
    username = 'test' + utils.randomString(8).toLowerCase()
    password = utils.randomString 8
    email = utils.randomString(8) + '@gmail.com'

    agent.post '/account/register'
    .send
      csrf_token: csrf_token
      username: username
      email: email
      password: password
    .expect 200
    .expect 'set-cookie', /token=/
    .end (err, res) ->
      res.body.account_id.should.have.length 24
      {account_id} = res.body
      done err

  it 'POST register with existed username', (done) ->
    agent.post '/account/register'
    .send
      csrf_token: csrf_token
      username: username
      email: "#{utils.randomString 8}@gmail.com"
      password: password
    .expect 400
    .end (err, res) ->
      res.body.error.should.be.equal 'username_exist'
      done err

  it 'POST register with invalid email', (done) ->
    agent.post '/account/register'
    .send
      csrf_token: csrf_token
      username: "test#{utils.randomString(8).toLowerCase()}"
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
      res.body.account_id.should.be.equal account_id
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
    .expect 204
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
      res.body.account_id.should.be.equal account_id
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
