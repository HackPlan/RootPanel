{markdown} = require 'markdown'

{models, logger, mabolo} = app
{_, async} = app.libs
{ObjectID} = mabolo

Reply = mabolo.model 'Reply',
  account_id:
    required: true
    type: ObjectID
    ref: 'Account'

  content:
    required: true
    type: String

  content_html:
    required: true
    type: String

  created_at:
    required: true
    type: Date
    default: -> new Date()

Ticket = mabolo.model 'Ticket',
  account_id:
    required: true
    type: ObjectID
    ref: 'Account'

  title:
    required: true
    type: String

  status:
    required: true
    type: String
    enum: ['opening', 'pending', 'finished', 'closed']

  content:
    required: true
    type: String

  content_html:
    required: true
    type: String

  members: [ObjectID]
  replies: [Reply]

  created_at:
    required: true
    type: Date
    default: -> new Date()

  updated_at:
    required: true
    type: Date
    default: -> new Date()

Ticket.createTicket = (account, {title, content, status}) ->
  unless title?.trim()
    throw new Error 'empty_title'

  if account.isAdmin()
    status ?= 'open'
  else
    status = 'pending'

  @create
    account_id: account._id
    title: title
    status: status
    content: content
    content_html: markdown.toHTML content
    members: [account._id]
    replies: []

Ticket.getTickets = (account) ->
  @find
    $or: [
      account_id: account._id
    ,
      members: account._id
    ]
  ,
    sort:
      updated_at: -1

Ticket.getTicketsGroupByStatus = (account, options) ->
  getTicketsOfStatus = (status) =>
    @find
      status: status
    ,
      sort:
        updated_at: -1
      limit: options?[status]?.limit

  Q.all([
    getTicketsOfStatus 'pending'
    getTicketsOfStatus 'opening'
    getTicketsOfStatus 'finished'
    getTicketsOfStatus 'closed'
  ]).then ([pending, opening, finished, closed]) ->
    return {
      pending: pending
      opening: opening
      finished: finished
      closed: closed
    }

Ticket::hasMember = (account) ->
  return _.some @members, (member_id) ->
    return member_id.equals account._id

Ticket::setStatusByAccount = (account, status) ->
  if account.isAdmin()
    unless status in ['open', 'pending', 'finish', 'closed']
      throw new Error 'invalid_status'
  else
    unless status in ['closed']
      throw new Error 'invalid_status'

  @setStatus status

Ticket::setStatus = (status) ->
  unless status in ['open', 'pending', 'finish', 'closed']
    throw new Error 'invalid_status'

  @update
    $set:
      status: status
      updated_at: new Date()

Ticket::createReply = (account, {content, status}) ->
  if @status == 'closed'
    throw new Error 'already_closed'

  unless content?.trim()
    throw new Error 'empty_content'

  if account.isAdmin()
    status ?= 'open'
  else
    status = 'pending'

  reply = new Reply
    _id: new ObjectID()
    account_id: account._id
    content: content
    content_html: markdown.toHTML content
    created_at: new Date()

  @update
    $push:
      replies: reply
    $set:
      status: status
      updated_at: new Date()

  .thenResolve reply

Ticket::populateAccounts = ->
  Account.find
    _id:
      $in: [
        @account_id, @members..., _.pluck(@replies, 'account_id')...
      ]

  .then (accounts) =>
    @account = _.find accounts, ({_id}) =>
      return @account_id.equals _id

    @members = _.filter accounts, ({_id}) =>
      return @hasMember _id

    for reply in @replies
      reply.account = _.find accounts, ({_id}) ->
        return reply.account_id.equals _id

    return @
