markdown = require('markdown').markdown

module.exports = exports = app.db.buildModel 'tickets'

sample =
  account_id: ObjectID()
  created_at: Date()
  updated_at: Date()
  title: 'Ticket Title'
  content: 'Ticket Content(Markdown)'
  content_html: 'Ticket Conetnt(HTML)'
  status: 'open/pending/finish/closed'

  attribute:
    public: false

  members: [
    ObjectID()
  ],

  replys: [
    _id: ObjectID()
    account_id: ObjectID()
    created_at: Date()
    content: 'Reply Content(Markdown)'
    content_html: 'Reply Conetnt(HTML)'
    attribute: {}
  ]

exports.createTicket = (account, title, content, members, status, attribute, callback) ->
  membersID = []

  for member in members
    membersID.push member._id

  exports.insert
    account_id: account._id
    created_at: new Date()
    updated_at: new Date()
    title: title
    content: content
    content_html: markdown.toHTML content
    status: status
    members: membersID
    attribute: attribute
    replys: []
  , (err, result) ->
    callback err, result?[0]

exports.createReply = (ticket, account, content, status, callback) ->
  data =
    _id: new ObjectID()
    account_id: account._id
    created_at: new Date()
    content: content
    content_html: markdown.toHTML content
    attribute: {}

  exports.update _id: ticket._id,
    $push:
      replys: data
    $set:
      status: status
      updated_at: new Date()
  , ->
    unless exports.getMember ticket, account
      exports.addMember ticket, account, ->
        callback null, data
    else
      callback null, data

exports.addMember = (ticket, account, callback) ->
  exports.update _id: ticket._id,
    $push:
      members: account._id
    updated_at: new Date()
  , callback

exports.getMember = (ticket, account) ->
  return _.find(ticket.members, (member) -> member.equals(account._id))
