describe 'router/coupon', ->
  agent = null
  coupon3 = null
  csrf_token = null

  before ->
    {agent, csrf_token} = namespace.accountRouter
    {coupon3} = namespace.couponCodeModel

  it 'GET coupon_info', (done) ->
    agent.get '/coupon/coupon_info'
    .query
      code: coupon3.code
    .expect 200
    .end (err, res) ->
      res.body.message.should.be.equal '账户余额：4 CNY'
      done err

  it 'POST apply_coupon', (done) ->
    agent.post '/coupon/apply_coupon'
    .send
      csrf_token: csrf_token
      code: coupon3.code
    .expect 200
    .end done
