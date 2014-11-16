{models, logger} = app
{Account} = app.models
{_, ObjectId, mongoose, markdown, async} = app.libs

process.nextTick ->
  {Account} = app.models

Reply = mongoose.Schema
  account_id:
    required: true
    type: ObjectId
    ref: 'Account'

  created_at:
    type: Date
    default: Date.now

  content:
    required: true
    type: String

  content_html:
    type: String

  flags:
    type: Object

_.extend app.models,
  Reply: mongoose.model 'Reply', Reply

Ticket = mongoose.Schema
  account_id:
    required: true
    type: ObjectId
    ref: 'Account'

  created_at:
    type: Date
    default: Date.now

  updated_at:
    type: Date
    default: Date.now

  title:
    required: true
    type: String

  content:
    required: true
    type: String

  content_html:
    type: String

  status:
    required: true
    type: String
    enum: ['open', 'pending', 'finish', 'closed']

  flags:
    type: Object

  members: [
    ObjectId
  ]

  replies: [
    mongoose.modelSchemas.Reply
  ]

Ticket.pre 'save', (next) ->
  @content_html = markdown.toHTML @content
  next()

Ticket.methods.createReply = (account, content, status, flags, callback) ->
  reply = new models.Reply
    account_id: account._id
    content: content
    content_html: markdown.toHTML content
    flags: flags

  reply.validate (err) =>
    return callback err if err

    @replies.push reply
    @members.addToSet account._id
    @status = status
    @update_at = new Date()

    @save (err) ->
      callback err, reply

Ticket.methods.hasMember = (account) ->
  for member in @members
    if member.equals account._id
      return true

  return false

Ticket.methods.populateAccounts = (callback) ->
  accounts_id = _.uniq [@account_id].concat @members.concat _.pluck(@replies, 'account_id')

  async.map accounts_id, (account_id, callback) ->
    Account.findById account_id, callback

  , (err, accounts) =>
    logger.error err if err

    accounts = _.indexBy _.compact(accounts), '_id'

    result = @toObject()

    result.account = accounts[result.account_id]

    result.members = _.map result.members, (member_id) ->
      return accounts[member_id]

    for reply in result.replies
      reply.account = accounts[reply.account_id]

    callback result

_.extend app.models,
  Ticket: mongoose.model 'Ticket', Ticket
