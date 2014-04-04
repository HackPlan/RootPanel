markdown = require('markdown').markdown
ObjectID = require('mongodb').ObjectID
_ = require 'underscore'

Model = require './Model'

module.exports = class Ticket extends Model
  @create: (data) ->
    new Ticket data

  @createTicket: (account, title, content, type, members, attribute, callback) ->
    membersID = []
    for member in members
      membersID.push member.id()

    @insert
      account_id: account.id()
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
    , (ticket) ->
      callback ticket

  createReply: (account, reply_to, content, callback) ->
    if reply_to and _.isString reply_to
      reply_to = new ObjectID reply_to

    unless reply_to
      reply_to = null

    data =
      _id: new ObjectID()
      reply_to: reply_to
      account_id: account.id()
      created_at: new Date()
      content: content
      content_html: markdown.toHTML content
      attribute: {}

    @update
      $push:
        replys: data
    , =>
      unless @hasMember account
        @addMember account, ->
          callback data
      else
        callback data

  addMember: (member, callback) ->
    @update
      $push:
        members: member.id()
    , ->
      callback()

  hasMember: (account) ->
    if _.find(@data.members, (member) -> member.equals(account.id()))
      return true
    else
      return false
