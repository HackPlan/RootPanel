describe 'router.tickets', ->
  agent = createLoggedAgent
    baseUrl: '/tickets'

  ticket_id = null

  it 'POST tickets', ->
    agent.post '/',
      json:
        title: 'Title'
        content: '**CONTENT**'
    ,
      body:
        status: 'pending'
    .then ({body}) ->
      ticket_id = body._id

  it 'GET tickets', ->
    agent.get '/'
    .then ({body}) ->
      body.length.should.be.equal 1

  it 'POST /:id/replies', ->
    agent.post "/#{ticket_id}/replies",
      json:
        content: 'Reply'
    .then ({body}) ->
      body._id.should.be.eixst
      body.content.should.be.equal 'Reply'

  it 'GET /:id', ->
    agent.get "/#{ticket_id}"
    .then ({body}) ->
      body.replies.length.should.be.equal 1

  it 'PUT /:id/status', ->
    agent.put "/#{ticket_id}/status",
      json:
        status: 'closed'
