describe 'router/ticket', ->
  agent = null
  csrf_token = null

  ticket_id = null

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
      ticket_id = res.body.id
      created_objects.tickets.push ObjectId ticket_id
      done err

  it 'GET list', (done) ->
    agent.get '/ticket/list'
    .expect 200
    .expect /Title/
    .end done

  it 'GET view/:id', (done) ->
    agent.get "/ticket/view/#{ticket_id}"
    .expect 200
    .expect /<p><strong>CONTENT<\/strong><\/p>/
    .end done

  it 'POST reply', (done) ->
    agent.post "/ticket/reply/#{ticket_id}"
    .send
      csrf_token: csrf_token
      content: '**REPLY**'
    .expect 200
    .end done

  it 'GET list when replied', (done) ->
    agent.get "/ticket/view/#{ticket_id}"
    .expect 200
    .expect /<p><strong>CONTENT<\/strong><\/p>/
    .expect /<p><strong>REPLY<\/strong><\/p>/
    .end done

  it 'POST update_status', (done) ->
    agent.post "/ticket/update_status/#{ticket_id}"
    .send
      csrf_token: csrf_token
      status: 'closed'
    .expect 200
    .end done

  it 'POST update_status with already closed', (done) ->
    agent.post "/ticket/update_status/#{ticket_id}"
    .send
      csrf_token: csrf_token
      status: 'closed'
    .expect 400
    .end done

  it 'POST update_status with no permission', (done) ->
    agent.post "/ticket/update_status/#{ticket_id}"
    .send
      csrf_token: csrf_token
      status: 'open'
    .expect 400
    .end done
