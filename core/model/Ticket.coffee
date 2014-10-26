{models} = app
{_, ObjectId, mongoose, markdown} = app.libs

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
    required: true
    type: String

  flags:
    type: Object

Reply.pre 'save', (next) ->
  @content_html = markdown.toHTML @content
  next()

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
    required: true
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

Ticket.createReply = (account, content, status, flags, callback) ->
  reply = new models.Reply
    account_id: account._id
    content: content
    flags: flags

  reply.validate (err) =>
    return callback err if err

    @replies.push reply
    @members.addToSet account._id
    @status = status
    @update_at = new Date()

    @save (err) ->
      callback err, reply

Ticket.hasMember = (account) ->
  for member in @members
    if member.equals account._id
      return true

  return false

_.extend app.models,
  Ticket: mongoose.model 'Ticket', Ticket
