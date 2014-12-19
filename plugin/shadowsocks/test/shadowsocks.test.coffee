ifEnabled('shadowsocks') 'plugin/shadowsocks', ->
  agent = null
  utils = null
  config = null
  Account = null

  csrf_token = null
  account_id = null

  before ->
    {utils, config} = app
    {Account} = app.models
    agent = supertest.agent app.express

    config.plans.shadowsocks =
      t_name: 'shadowsocks'
      t_description: 'shadowsocks'

      services: ['shadowsocks']

  describe 'router', ->
    it 'POST register', (done) ->
      agent.get '/account/session_info'
      .end (err, res) ->
        csrf_token = res.body.csrf_token

        agent.post '/account/register'
        .send
          csrf_token: csrf_token
          username: "test#{utils.randomString(20).toLowerCase()}"
          email: "#{utils.randomString 20}@gmail.com"
          password: utils.randomString 20
        .end (err, res) ->
          account_id = res.body.id
          created_objects.accounts.push ObjectId account_id

          Account.findByIdAndUpdate account_id,
            $set:
              'billing.balance': 10
          , ->
            done err

    it 'POST join_plan', (done) ->
      @timeout 10000
      agent.post '/billing/join_plan'
      .send
        csrf_token: csrf_token
        plan: 'shadowsocks'
      .expect 200
      .end done

    it 'POST reset_password'

    it 'POST switch_method'

    it 'POST leave_plan'
