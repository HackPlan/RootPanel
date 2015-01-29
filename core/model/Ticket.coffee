markdown = require('markdown').markdown

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

Ticket.create = (account, ticket, callback) ->
  {title, content, status} = ticket

  unless title?.trim()
    return callback 'empty_title'

  if account.isAdmin()
    status ?= 'open'
  else
    status = 'pending'

  # TODO: replace `ObjectID account._id.toString()` to `account._id`

  @__super__.constructor.create.call @,
    account_id: ObjectID account._id.toString()
    title: title
    status: status
    content: content
    content_html: markdown.toHTML content
    members: [ObjectID account._id.toString()]
    replies: []
  , callback

Ticket::hasMember = (account) ->
  return _.some @members, (member_id) ->
    return member_id.equals account._id

Ticket::setStatusByAccount = (account, status, callback) ->
  if account.isAdmin()
    unless status in ['open', 'pending', 'finish', 'closed']
      return callback 'invalid_status'
  else
    unless status in ['closed']
      return callback 'invalid_status'

  @setStatus status, callback

Ticket::setStatus = (status, callback) ->
  # TODO: validate status

  @update
    $set:
      status: status
      updated_at: new Date()
  , callback

Ticket::createReply = (account, reply, callback) ->
  {content, status} = reply

  # TODO: cant reply after closed

  unless content?.trim()
    return callback 'empty_content'

  if account.isAdmin()
    status ?= 'open'
  else
    status = 'pending'

  reply = new Reply
    _parent: @
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
  , (err) ->
    callback err, reply

Ticket::populateAccounts = (callback) ->
  {Account} = app.models

  async.parallel [
    (callback) =>
      Account.findById @account_id, (err, account) =>
        @account = account
        callback err

    (callback) =>
      Account.find
        _id:
          $in: @members
      , (err, accounts) =>
        @members = accounts
        callback err

    (callback) =>
      Account.find
        _id:
          $in: _.pluck @replies, 'account_id'
      , (err, accounts) =>
        for reply in @replies
          reply.account = _.find accounts, (account) ->
            return reply.account_id.equals account._id

        callback err

  ], callback
