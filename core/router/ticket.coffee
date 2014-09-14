markdown = require 'markdown'
express = require 'express'

{requireAuthenticate, renderAccount, getParam, loadTicket} = app.middleware
{mAccount, mTicket} = app.models
{config, notification} = app

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

exports.get '/view', renderAccount, getParam, loadTicket, (req, res) ->
  {ticket} = req

  async.map ticket.members, (member_id, callback) ->
    mAccount.findOne _id: member_id, callback
  , (err, result) ->
    ticket.members = result

    async.map ticket.replies, (reply, callback) ->
      mAccount.findOne _id: reply.account_id, (err, account) ->
        reply.account = account
        callback null, reply

    , (err, result) ->
      ticket.replies = result

      mAccount.findOne _id: ticket.account_id, (err, account) ->
        ticket.account = account

        res.render 'ticket/view',
          ticket: ticket

exports.post '/create', requireAuthenticate, (req, res) ->
  unless /^.+$/.test req.body.title
    return res.error 'invalid_title'

  is_admin = 'root' in req.account.groups

  createTicket = (members, status, callback) ->
    mTicket.createTicket req.account, req.body.title, req.body.content, members, status, {}, (err, ticket) ->
      res.json
        id: ticket._id
      callback ticket

  if is_admin
    req.body.members ?= []

    async.each req.body.members, (member_name, callback) ->
      mAccount.byUsernameOrEmailOrId member_name, (err, member) ->
        if member
          callback null, member
        else
          callback member_name
    , (err, result) ->
      if err
        return res.error 'invalid_account', username: err
      else
        unless _.find(result, (item) -> item._id == req.account._id)
          result.push req.account

        createTicket result, 'open'

  else
    createTicket [req.account], 'pending', (ticket) ->
      notification.createGroupNotice 'root', 'ticket_create',
        title: _.template res.t('notification.ticket_create.title'), ticket
        body: _.template fs.readSync('./../template/ticket_create_email.html'),
          ticket: ticket
          account: req.account
          config: config
      , ->

exports.post '/reply', loadTicket, (req, res) ->
  {ticket} = req

  status = if 'root' in req.account.groups then 'open' else 'pending'

  mTicket.createReply ticket, req.account, req.body.content, status, (err, reply) ->
    async.each ticket.members, (member_id, callback) ->
      if member_id.toString() == req.account._id.toString()
        return callback()

      mAccount.findOne
        _id: member_id
      , (err, account) ->
        notification.createNotice account, 'ticket_reply',
          title: _.template res.t('notification.ticket_create.title'), ticket
          body: _.template fs.readSync('./../template/ticket_create_email.html'),
            ticket: ticket
            reply: reply
            account: req.account
            config: config
        , ->
          callback()

    , ->
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

exports.post '/update', loadTicket, (req, res) ->
  {ticket} = req

  modifier = {}

  addToSetModifier = []
  pullModifier = []

  if req.body.status
    if 'root' in req.account.groups
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
          mTicket.update {_id: ticket._id},
            $set: modifier
          , callback
        else
          callback()

      (callback) ->
        unless _.isEmpty addToSetModifier
          mTicket.update {_id: ticket._id},
            $addToSet:
              members:
                $each: addToSetModifier
          , callback
        else
          callback()

      (callback) ->
        unless _.isEmpty pullModifier
          mTicket.update {_id: ticket._id},
            $pullAll:
              members: pullModifier
          , callback
        else
          callback()
    ], ->
      return res.json {}

  if 'root' in req.account.groups
    if req.body.payload
      if req.body.payload.public
        modifier['payload.public'] = true
      else
        modifier['payload.public'] = false

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
