describe 'router/coupon', ->
  agent = null

  before ->
    require '../../../app'
    agent = supertest.agent app.express

  it 'GET coupon_info'

  it 'POST apply_coupon'
