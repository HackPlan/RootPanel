describe 'plugin/rpvhost', ->
  agent = null

  before ->
    agent = supertest.agent app.express

  describe 'router', ->
    it 'GET /', (done) ->
      agent.get '/'
      .redirects 0
      .expect 200
      .end done
