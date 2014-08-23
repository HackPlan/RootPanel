markdown = require('markdown').markdown

{requireAuthenticate, renderAccount, getParam} = require './middleware'

mAccount = require '../model/account'
mTicket = require '../model/ticket'

module.exports = exports = express.Router()

exports.get '/list', requireAuthenticate, renderAccount, (req, res) ->
  mTicket.find
    $or: [
      account_id: req.account._id
    ,
      members: req.account._id
    ]
  ,
    sort:
      updated_at: -1
  .toArray (err, tickets) ->
    res.render 'ticket/list',
      tickets: tickets

exports.get '/create', requireAuthenticate, renderAccount, (req, res) ->
  res.render 'ticket/create'

exports.get '/view', requireAuthenticate, renderAccount, getParam, (req, res) ->
  mTicket.findId req.body.id, (err, ticket) ->
    unless ticket
      return res.send 404

    unless mAccount.inGroup req.account, 'root'
      unless mTicket.getMember ticket, req.account
        return res.send 403

    async.map ticket.members, (member, callback) ->
      mAccount.findId member, (err, member_account) ->
        callback null, member_account
    , (err, result) ->
      ticket.members = result

      async.map ticket.replys, (reply, callback) ->
        mAccount.findId reply.account_id, (err, reply_account) ->
          reply.account = reply_account
          callback null, reply

      , (err, result) ->
        ticket.replys = result

        mAccount.findId ticket.account_id, (err, ticket_account) ->
          ticket.account = ticket_account

          res.render 'ticket/view',
            ticket: ticket

exports.post '/create', requireAuthenticate, (req, res) ->
  unless /^.+$/.test req.body.title
    return res.error 'invalid_title'

  createTicket = (members, status, callback) ->
    mTicket.createTicket req.account, req.body.title, req.body.content, members, status, {}, (err, ticket) ->
      res.json
        id: ticket._id
      callback ticket

  if mAccount.inGroup req.account, 'root'
    tasks = []

    if req.body.members
      for memberName in req.body.members
        do (memberName = _.clone(memberName)) ->
          tasks.push (callback) ->
            mAccount.byUsernameOrEmailOrId memberName, (err, member) ->
              unless member
                res.error 'invalid_account', username: memberName
                callback true

              callback null, member

    async.parallel tasks, (err, result) ->
      if err
        return

      unless _.find(result, (item) -> item._id == req.account._id)
        result.push req.account

      createTicket result, 'open', ->

  else
    createTicket [req.account], 'pending', (ticket) ->
      mTicket.sendMailToAdmins "Ticket | #{req.body.title}", "#{ticket.content_html}\n<br /><br />\n#{req.account.username} <a href='#{config.web.url}/ticket/view/?id=#{ticket._id}'>#{ticket._id}</a>"

exports.post '/reply', requireAuthenticate, (req, res) ->
  mTicket.findId req.body.id, (errr, ticket) ->
    unless ticket
      return res.error 'ticket_not_exist'

    unless mTicket.getMember ticket, req.account
      unless mAccount.inGroup req.account, 'root'
        return res.error 'forbidden'

    status = if mAccount.inGroup(req.account, 'root') then 'open' else 'pending'

    async.each ticket.members, (member_id, callback) ->
      if member_id.toString() == req.account._id.toString()
        return callback()

      mAccount.findOne
        _id: member_id
      , (err, account) ->
          mAccount.sendEmail account, "Ticket | #{ticket.title}", "#{markdown.toHTML(req.body.content)}\n<br /><br />\n#{req.account.username} <a href='#{config.web.url}/ticket/view/?id=#{ticket._id}'>#{ticket._id}</a>"
          callback()

    , ->
      mTicket.createReply ticket, req.account, req.body.content, status, (err, reply) ->
        return res.json
          id: reply._id

exports.post '/list', requireAuthenticate, (req, res) ->
  mTicket.find do ->
    selector =
      $or: [
          account_id: req.account._id
        ,
          members: req.account._id
      ]

    if req.body.status?.toLowerCase() in ['open', 'pending', 'finish', 'closed']
      selector['status'] = req.body.status.toLowerCase()

    return selector
  ,
    sort:
      updated_at: -1
    limit: req.body.limit ? 30
    skip: req.body.skip ? 0
  .toArray (err, tickets) ->
    res.json _.map tickets, (item) ->
      return {
        id: item._id
        title: item.title
        status: item.status
        updated_at: item.updated_at
      }

exports.post '/update', requireAuthenticate, (req, res) ->
  modifier = {}

  addToSetModifier = []
  pullModifier = []

  mTicket.findId req.body.id, (err, ticket) ->
    unless ticket
      return res.error 'ticket_not_exist'

    unless mTicket.getMember ticket, req.account
      unless mAccount.inGroup req.account, 'root'
        return res.error 'forbidden'

    if req.body.status
      if mAccount.inGroup req.account, 'root'
        allow_status = ['open', 'pending', 'finish', 'closed']
      else
        allow_status = ['closed']

      if req.body.status in allow_status
        if ticket.status == req.body.status
          return res.error 'already_in_status'
        else
          modifier['status'] = req.body.status
      else
        return res.error 'invalid_status'

    callback = ->
      async.parallel [
        (callback) ->
          unless _.isEmpty modifier
            mTicket.update _id: ticket._id,
              $set: modifier
            , callback
          else
            callback()

        (callback) ->
          unless _.isEmpty addToSetModifier
            mTicket.update _id: ticket._id,
              $addToSet:
                members:
                  $each: addToSetModifier
            , callback
          else
            callback()

        (callback) ->
          unless _.isEmpty pullModifier
            mTicket.update _id: ticket._id,
              $pullAll:
                members: pullModifier
            , callback
          else
            callback()
      ], ->
        return res.json {}

    if mAccount.inGroup req.account, 'root'
      if req.body.attribute
        if req.body.attribute.public
          modifier['attribute.public'] = true
        else
          modifier['attribute.public'] = false

      if req.body.members
        tasks = {}

        member_name = _.filter _.union(req.body.members.add, req.body.members.remove), (item) -> item
        for item in member_name
          tasks[item] = do (item = _.clone(item)) ->
            return (callback) ->
              mAccount.byUsernameOrEmailOrId item, (result) ->
                callback null, result

        async.parallel tasks, (err, result) ->
          if req.body.members.add
            for item in req.body.members.add
              addToSetModifier.push result[item]._id

          if req.body.members.remove
            for item in req.body.members.remove
              pullModifier.push result[item]._id

          callback()
      else
        callback()

    else
      callback()
