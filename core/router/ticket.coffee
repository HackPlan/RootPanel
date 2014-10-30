{_, async, express} = app.libs

{requireAuthenticate} = app.middleware
{Account, Ticket} = app.models
{config, notification, logger} = app

module.exports = exports = express.Router()

exports.use requireAuthenticate

exports.param 'id', (req, res, next, id) ->
  Ticket.findById id, (err, ticket) ->
    logger.error err if err

    unless ticket
      return res.error 'ticket_not_exist', null, 404

    unless ticket.hasMember req.account
      unless req.account.inGroup 'root'
        return res.error 'forbidden', null, 403

    req.ticket = ticket

    next()

exports.get '/list', (req, res) ->
  Ticket.find
    $or: [
      account_id: req.account._id
    ,
      members: req.account._id
    ]
  , null,
    sort:
      updated_at: -1
  , (err, tickets) ->
    logger.error err if err
    res.render 'ticket/list',
      tickets: tickets

exports.get '/create', (req, res) ->
  res.render 'ticket/create'

exports.get '/view/:id', (req, res) ->
  req.ticket.populateAccounts ->
    res.render 'ticket/view',
      ticket: req.ticket

exports.post '/create', (req, res) ->
  unless /^.+$/.test req.body.title
    return res.error 'invalid_title'

  Ticket.create
    account_id: req.account._id
    title: req.body.title
    content: req.body.content
    status: if req.account.inGroup 'root' then 'open' else 'pending'
    members: [req.account._id]
  , (err, ticket) ->
    logger.error err if err

    res.json
      id: ticket._id

    notification.createGroupNotice 'root', 'ticket_create',
      title: res.t 'notification_title.ticket', ticket
      body: _.template(app.templates['ticket_create_email'])
        t: res.t
        ticket: ticket
        account: req.account
        config: config
    , ->

exports.post '/reply/:id', (req, res) ->
  {ticket} = req

  unless req.body.content
    return res.error 'invalid_content'

  status = if 'root' in req.account.groups then 'open' else 'pending'

  ticket.createReply req.account, content, status, {}, (err, reply) ->
    logger.error err if err

    res.json
      id: reply._id

    async.each ticket.members, (member_id, callback) ->
      if member_id.toString() == req.account._id.toString()
        return callback()

      Account.findOne
        _id: member_id
      , (err, account) ->
        notification.createNotice account, 'ticket_reply',
          title: res.t 'notification_title.ticket', ticket
          body: _.template(app.templates['ticket_reply_email'])
            t: res.t
            ticket: ticket
            reply: reply
            account: req.account
            config: config
        , ->
          callback()
    , ->

exports.post '/update_status/:id', (req, res) ->
  {ticket} = req

  if req.account.inGroup 'root'
    allow_status = ['open', 'pending', 'finish', 'closed']
  else
    allow_status = ['closed']

  if req.body.status in allow_status
    if ticket.status == req.body.status
      return res.error 'already_in_status'
  else
    return res.error 'invalid_status'

  ticket.update
    $set:
      status: req.body.status
  , ->
    res.json {}
