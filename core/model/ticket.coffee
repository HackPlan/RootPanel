markdown = require('markdown').markdown
ObjectID = require('mongodb').ObjectID
_ = require 'underscore'

db = require '../db'

cTicket = db.collection 'tickets'

db.buildModel module.exports, cTicket

exports.createTicket = (account, title, content, type, members, attribute, callback) ->
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
    type: type
    status: 'open'
    members: membersID
    attribute: attribute
    replys: []
  , {}, callback

exports.createReply = (ticket, account, reply_to, content, callback) ->
  if reply_to and _.isString reply_to
    reply_to = new db.ObjectID reply_to

  data =
    _id: db.ObjectID()
    reply_to: reply_to ? null
    account_id: account._id
    created_at: new Date()
    content: content
    content_html: markdown.toHTML content
    attribute: {}

  exports.update _id: ticket._id,
    $push:
      replys: data
  , ->
    unless exports.getMember ticket, account
      exports.addMember ticket, account, ->
        callback data
    else
      callback data

exports.addMember = (ticket, account, callback) ->
  exports.update
    $push:
      members: account._id
  , callback

exports.getMember = (ticket, account) ->
  return _.find(ticket.members, (member) -> member.equals(account._id))
