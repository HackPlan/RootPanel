describe.skip 'router/panel', ->
  agent = null

  before ->
    {agent} = namespace.accountRouter

  it 'GET /', (done) ->
    agent.get '/panel'
    .expect 200
    .end done

  it.skip 'GET pay', (done) ->
    agent.get '/panel/financials'
    .expect 200
    .end done
