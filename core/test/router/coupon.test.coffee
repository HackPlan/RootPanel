describe 'router/coupon', ->
  agent = null
  coupon3 = null
  csrf_token = null

  before ->
    {agent, csrf_token} = namespace.accountRouter
    {coupon3} = namespace.couponCodeModel

  it.skip 'GET info', (done) ->
    agent.get '/coupon/info'
    .query
      code: coupon3.code
    .expect 200
    .end (err, res) ->
      res.body.message.should.be.equal '代金券：4 CNY'
      done err

  it 'POST apply', (done) ->
    agent.post '/coupon/apply'
    .send
      csrf_token: csrf_token
      code: coupon3.code
    .expect 200
    .end done
