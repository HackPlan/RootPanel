markdown = require('markdown').markdown

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
