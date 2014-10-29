after (done) ->
  app.models.Ticket.remove
    account_id:
      $in: created_objects.accounts
  , done

describe 'model/Ticket', ->
  Ticket = null

  account = null
  ticket = null

  before ->
    {Ticket} = app.models
    {account} = namespace.accountModel

  it 'should render markdown before save', (done) ->
    Ticket.create
      account_id: account._id
      title: 'Title'
      content: '**CONTENT**'
      status: 'open'
    , (err, created_ticket) ->
      expect(err).to.not.exist
      ticket = created_ticket

      created_objects.tickets.push ticket._id

      ticket.title.should.be.equal 'Title'
      ticket.content_html.should.be.equal '<p><strong>CONTENT</strong></p>'

      done()

  describe 'createReply', ->
    it 'should success', (done) ->
      ticket.createReply account, '**REPLY**', 'pending', {}, (err, reply) ->
        expect(err).to.not.exist

        reply.content_html.should.be.equal '<p><strong>REPLY</strong></p>'
        reply.account_id.toString().should.be.equal account.id

        Ticket.findById ticket._id, (err, ticket) ->
          ticket.status.should.be.equal 'pending'
          ticket.replies.should.have.length 1
          done()

  describe 'hasMember', ->
    it 'should success', ->
      ticket.hasMember(account).should.be.ok
