{models, logger} = app
{_, markdown, async, mongoose} = app.libs

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
  @set
    content_html: markdown.toHTML @content

  next()

# @callback(err, reply)
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

    @set
      status: status
      update_at: new Date()

    @save (err) ->
      callback err, reply

# return bool
Ticket.methods.hasMember = (account) ->
  for member in @members
    if member.equals account._id
      return true

  return false

# @param callback({#id: #account})
Ticket.methods.populateAccounts = (callback) ->
  accounts_id = _.uniq [@account_id].concat @members.concat _.pluck(@replies, 'account_id')

  app.models.Account.find
    _id:
      $in: accounts_id
  , (err, accounts) ->
    logger.error err if err
    callback _.indexBy accounts, '_id'

_.extend app.models,
  Ticket: mongoose.model 'Ticket', Ticket
