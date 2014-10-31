describe 'router/billing', ->
  Account = null

  agent = null
  account_id = null
  csrf_token = null

  before ->
    {Account} = app.models
    {agent, csrf_token, account_id} = namespace.accountRouter

  it 'POST join_plan when balance = 0', (done) ->
    agent.post '/billing/join_plan'
    .send
      csrf_token: csrf_token
      plan: 'billing_test'
    .expect 400
    .end (err, res) ->
      res.body.error.should.be.equal 'insufficient_balance'
      done err

  it 'POST join_plan', (done) ->
    Account.findByIdAndUpdate account_id,
      $set:
        'billing.balance': 10
    , ->
      agent.post '/billing/join_plan'
      .send
        csrf_token: csrf_token
        plan: 'billing_test'
      .expect 200
      .end done

  it 'POST join_plan when already joined', (done) ->
    agent.post '/billing/join_plan'
    .send
      csrf_token: csrf_token
      plan: 'billing_test'
    .expect 400
    .end (err, res) ->
      res.body.error.should.be.equal 'already_in_plan'
      done err

  it 'POST leave_plan', (done) ->
    agent.post '/billing/leave_plan'
    .send
      csrf_token: csrf_token
      plan: 'billing_test'
    .expect 200
    .end done
