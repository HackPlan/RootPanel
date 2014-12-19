ifEnabled('rpvhost') 'plugin/rpvhost', ->
  agent = null

  before ->
    agent = supertest.agent app.express

  describe.skip 'router', ->
    it 'GET /', (done) ->
      if config.plugins.rpvhost and config.plugins.rpvhost.index_page != false
        expect_code = 200
      else
        expect_code = 302

      agent.get '/'
      .redirects 0
      .expect expect_code
      .end done
