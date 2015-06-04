describe 'model.ticket', ->
  Ticket = require '../../model/ticket'

  describe '.createTicket', ->
    it 'should success', ->
      createAccount().then (account) ->
        Ticket.createTicket(account,
          title: 'Title'
          content: 'Content'
        ).then (ticket) ->
          ticket.status.should.be.equal 'pending'

  describe '.getTicketsGroupByStatus', ->
    it 'should success', ->
      createAccount().then (account) ->
        Q.all([1..3].map -> createTicket {account}).then ->
          Ticket.getTicketsGroupByStatus(account).then ({pending, opening}) ->
            pending.length.should.be.equal 3
            opening.length.should.be.equal 0

  describe '::createReply', ->
    it 'should success', ->
      createAccount().then (account) ->
        createTicket({account}).then (ticket) ->
          ticket.createReply(account,
            content: 'Reply'
          ).then (reply) ->
            reply.account_id.equals(account._id).should.be.true
            ticket.replies.length.should.be.equal 1

  describe '::setStatusByAccount', ->
    it 'should success', ->
      createTicket().then (ticket) ->
        createAdmin().then (admin) ->
          ticket.setStatusByAccount(admin, 'closed').then ->
            ticket.status.should.be.equal 'closed'

  describe '::populateAccounts', ->
    it 'should success', ->
      createTicket().then (ticket) ->
        ticket.populateAccounts().then ->
          ticket.account.should.be.exists

createTicket = (options) ->
  createAccount().then (account) ->
    root.Ticket.createTicket (options?.account ? account),
      title: 'Title'
      content: 'Content'
