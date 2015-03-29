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
    enum: ['open', 'pending', 'finish', 'closed']

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

Ticket.create = (account, {title, content, status}) ->
  unless title?.trim()
    throw new Error 'empty_title'

  if account.isAdmin()
    status ?= 'open'
  else
    status = 'pending'

  @__super__.constructor.create.call @,
    account_id: account._id
    title: title
    status: status
    content: content
    content_html: markdown.toHTML content
    members: [account._id]
    replies: []

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

Ticket::createReply = (account, {content, status}, callback) ->
  {content, status} = reply

  if @status == 'closed'
    throw new Error 'already_closed'

  unless content?.trim()
    throw new Error 'empty_content'

  if account.isAdmin()
    status ?= 'open'
  else
    status = 'pending'

  reply = new Reply
    account_id: account._id
    content: content
    content_html: markdown.toHTML content
    created_at: new Date()

  @update(
    $push:
      replies: reply
    $set:
      status: status
      updated_at: new Date()
  ).thenResolve reply

Ticket::populateAccounts = ->
  app.models.Account.find
    _id:
      $in: [
        @account_id, @members..., _.pluck(@replies, 'account_id')...
      ]

  .then (accounts) =>
    @account = _.find accounts, (i) =>
      return @account_id.equals i

    @members = _.filter accounts, (i) =>
      return @hasMember i

    for reply in @replies
      reply.account = _.find accounts, (i) ->
        return reply.account_id.equals account._id
