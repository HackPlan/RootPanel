{ObjectID} = require 'mongodb'
{markdown} = require 'markdown'
_ = require 'underscore'

module.exports = exports = app.db.collection 'tickets'

mAccount = require './account'

sample =
  account_id: ObjectID()
  created_at: Date()
  updated_at: Date()
  title: 'Ticket Title'
  content: 'Ticket Content(Markdown)'
  content_html: 'Ticket Conetnt(HTML)'
  status: 'open/pending/finish/closed'

  options: {}

  members: [
    ObjectID()
  ]

  replies: [
    _id: ObjectID()
    account_id: ObjectID()
    created_at: Date()
    content: 'Reply Content(Markdown)'
    content_html: 'Reply Conetnt(HTML)'
    options: {}
  ]

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
