ifEnabled('wiki') 'plugin/wiki', ->
  agent = null

  describe.skip 'router', ->
    it 'GET /', (done) ->
      agent.get '/wiki'
      .expect 200
      .end done

    it 'GET /:category/:title', (done) ->
      agent.get '/wiki/FAQ/Billing.md'
      .expect if config.plugins.wiki?.disable_default_wiki then 404 else 200
      .end done

    it 'GET /:category/:title when not exist', (done) ->
      agent.get '/wiki/FAQ/not_exist'
      .expect 404
      .end done
