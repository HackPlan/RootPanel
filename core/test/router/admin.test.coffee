describe.skip 'router/admin', ->
  utils = null
  Account = null

  agent = null
  csrf_token = null
  account_id = null

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

  it 'should create a account for test', (done) ->
    Account.register
      username: "account#{utils.randomString(10).toLowerCase()}"
      email: "#{utils.randomString 20}@gmail.com"
      password: utils.randomString 20
    , (err, account) ->
      created_objects.accounts.push account._id
      account_id = account._id
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

  it 'GET ticket', (done) ->
    agent.get '/admin/ticket'
    .expect 200
    .end done

  it 'POST confirm_payment', (done) ->
    agent.post '/admin/confirm_payment'
    .send
      csrf_token: csrf_token
      account_id: account_id
      amount: 10
      order_id: 'ID'
    .expect 200
    .end done

  it 'POST confirm_payment with account_id not exist', (done) ->
    agent.post '/admin/confirm_payment'
    .send
      csrf_token: csrf_token
      account_id: '14534f8a3d9064cb116c315d'
      amount: 10
      order_id: 'ID'
    .expect 400
    .end (err, res) ->
      res.body.error.should.be.equal 'account_not_exist'
      done err

  it 'POST confirm_payment with invalid amount', (done) ->
    agent.post '/admin/confirm_payment'
    .send
      csrf_token: csrf_token
      account_id: account_id
      amount: '1x'
    .expect 400
    .end (err, res) ->
      res.body.error.should.be.equal 'invalid_amount'
      done err

  it 'POST delete_account', (done) ->
    Account.findByIdAndUpdate account_id,
      $set:
        'billing.balance': 0
    , ->
      agent.post '/admin/delete_account'
      .send
        csrf_token: csrf_token
        account_id: account_id
      .expect 200
      .end (err) ->
        Account.findById account_id, (mongo_err, account) ->
          expect(mongo_err).to.not.exist
          expect(account).to.not.exist
          done err

  it 'POST generate_coupon_code', (done) ->
    agent.post '/admin/generate_coupon_code'
    .send
      csrf_token: csrf_token
      count: 2
      available_times: 3
      type: 'amount'
      meta:
        category: 'test'
        amount: 4
    .expect 200
    .end (err, res) ->
      res.body.should.have.length 2
      [coupon1, coupon2] = res.body

      coupon1.available_times.should.be.equal 3
      coupon1.type.should.be.equal 'amount'
      coupon1.meta.amount.should.be.equal 4

      coupon1.code.should.not.equal coupon2.code

      created_objects.couponcodes.push ObjectId coupon1._id
      created_objects.couponcodes.push ObjectId coupon2._id

      done err
