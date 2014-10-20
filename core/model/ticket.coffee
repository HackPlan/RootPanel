{pluggable} = app
{selectModelEnum} = pluggable
{_, ObjectId, mongoose} = app.libs

Reply = mongoose.Schema
  _id:
    type: ObjectId

  account_id:
    required: true
    type: ObjectId
    ref: 'Account'

  created_at:
    type: Date
    default: Date.now

  content:
    type: String

  content_html:
    type: String

  option:
    type: Object
    default: {}

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
    type: String

  content:
    type: String

  content_html:
    type: String

  status:
    type: String
    enum: ['open', 'pending', 'finish', 'closed'].concat selectModelEnum 'Ticket', 'type'

  option:
    type: Object
    default: {}

  members: [
    ObjectId
  ]

  replies: [
    Reply
  ]

_.extend app.schemas,
  Ticket: Ticket

exports.createTicket = (account, title, content, members, status, options, callback) ->
  exports.insert
    account_id: account._id
    created_at: new Date()
    updated_at: new Date()
    title: title
    content: content
    content_html: markdown.toHTML content
    status: status
    members: _.pluck members, '_id'
    options: options
    replies: []
  , (err, result) ->
    callback _.first result

exports.createReply = (ticket, account, content, status, callback) ->
  reply =
    _id: new ObjectID()
    account_id: account._id
    created_at: new Date()
    content: content
    content_html: markdown.toHTML content
    options: {}

  exports.update {_id: ticket._id},
    $push:
      replies: reply
    $addToSet:
      members: account._id
    $set:
      status: status
      updated_at: new Date()
  , ->
    callback reply

exports.getMember = (ticket, account) ->
  return _.find(ticket.members, (member) -> member.equals(account._id))
