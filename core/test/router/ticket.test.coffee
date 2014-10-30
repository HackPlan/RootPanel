describe 'router/ticket', ->
  agent = null
  csrf_token = null

  before ->
    {agent, csrf_token} = namespace.accountRouter

  it 'GET create with not logged', (done) ->
    supertest app.express
    .get '/ticket/create'
    .redirects 0
    .expect 302
    .expect 'location', '/account/login/'
    .end done

  it 'GET create', (done) ->
    agent.get '/ticket/create'
    .expect 200
    .end done

  it 'POST create', (done) ->
    agent.post '/ticket/create'
    .send
      csrf_token: csrf_token
      title: 'Title'
      content: '**CONTENT**'
    .expect 200
    .end (err, res) ->
      created_objects.tickets.push res.body.id
      done err

  it 'GET list'

  it 'GET view/:id'

  it 'POST reply'

  it 'GET list when replied'

  it 'POST update_status'
