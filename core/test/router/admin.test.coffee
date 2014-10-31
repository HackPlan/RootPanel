describe 'router/admin', ->
  utils = null
  Account = null

  agent = null
  csrf_token = null

  before ->
    {utils} = app
    {Account} = app.models
    agent = supertest.agent app.express

  it 'should create a admin account first', (done) ->
    username = "admin#{utils.randomString(10).toLowerCase()}"
    password = utils.randomString 20

    Account.register
      username: username
      email: "#{utils.randomString 20}@gmail.com"
      password: password
    , (err, admin) ->
      created_objects.accounts.push admin._id

      admin.groups.push 'root'
      admin.save ->
        agent.get '/account/session_info'
        .expect 200
        .end (err, res) ->
          csrf_token = res.body.csrf_token

          agent.post '/account/login'
          .send
            csrf_token: csrf_token
            username: username
            password: password
          .end (err, res) ->
            res.body.token.should.be.exist
            done err

  it 'GET / when no permission', (done) ->
    namespace.accountRouter.agent
    .get '/admin'
    .expect 403
    .end done

  it 'GET /', (done) ->
    agent.get '/admin'
    .expect 200
    .end done

  it 'GET ticket'

  it 'POST confirm_payment'

  it 'POST delete_account'

  it 'POST update_site'

  it 'POST generate_coupon_code'
