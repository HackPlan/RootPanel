describe 'ticket.user', ->
  agent = null
  csrf_token = null

  ticket_id = null

  before (done) ->
    createLoggedAgent (err, result) ->
      {agent, csrf_token} = result
      done err

  it 'POST /', (done) ->
    agent.post '/ticket/rest/'
    .send
      csrf_token: csrf_token
      title: 'Title'
      content: '**CONTENT**'
    .expect 201
    .end (err, res) ->
      res.body.status.should.be.equal 'pending'
      ticket_id = res.body._id
      done err

  it 'GET /', (done) ->
    agent.get '/ticket/rest/'
    .expect 200
    .end (err, res) ->
      res.body.should.be.a 'array'
      done err

  it 'POST /:id/replies', (done) ->
    agent.post "/ticket/rest/#{ticket_id}/replies"
    .send
      csrf_token: csrf_token
      content: 'Reply'
    .expect 201
    .end (err, res) ->
      res.body._id.should.be.eixst
      res.body.content.should.be.equal 'Reply'
      done err

  it 'GET /:id', (done) ->
    agent.get "/ticket/rest/#{ticket_id}"
    .expect 200
    .end (err, res) ->
      res.body.replies.length.should.be.equal 1
      done err

  it 'PUT /:id/status', (done) ->
    agent.put "/ticket/rest/#{ticket_id}/status"
    .send
      csrf_token: csrf_token
      status: 'closed'
    .expect 204
    .end done
