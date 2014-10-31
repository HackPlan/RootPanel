describe 'router/panel', ->
  agent = null

  before ->
    {agent} = namespace.accountRouter

  it 'GET /', (done) ->
    agent.get '/panel'
    .expect 200
    .end done

  it 'GET pay', (done) ->
    agent.get '/panel/pay'
    .expect 200
    .end done
