{_, async, express} = app.libs
{requireAuthenticate, TODO} = app.middleware
{Account, Ticket} = app.models
{config, notification, logger} = app

module.exports = exports = express.Router()

exports.use requireAuthenticate

ticketParam = (req, res, next, id) ->
  Ticket.findById id, (err, ticket) ->
    logger.error err if err

    unless ticket
      return res.error 404, 'ticket_not_exist'

    unless ticket.hasMember req.account
      unless req.account.isAdmin()
        return res.error 403, 'forbidden'

    _.extend req,
      ticket: ticket

    next()

exports.param 'id', ticketParam

exports.use '/resource', do ->
  rest = new express.Router mergeParams: true
  rest.param 'id', ticketParam

  rest.get '/', (req, res) ->
    Ticket.find
      $or: [
        account_id: req.account._id
      ,
        members: req.account._id
      ]
    ,
      sort:
        updated_at: -1
    , (err, tickets) ->
      if err
        res.error err
      else
        res.json tickets

  rest.post '/', (req, res) ->
    Ticket.create req.account, req.body, (err, ticket) ->
      if err
        res.error err
      else
        res.status(201).json ticket

  rest.get '/:id', (req, res) ->
    req.ticket.populateAccounts (err) ->
      if err
        res.error err
      else
        res.json req.ticket

  rest.put '/:id', TODO

  rest.patch '/:id', TODO

  rest.delete '/:id', TODO

  rest.post '/:id/replies', (req, res) ->
    req.ticket.createReply req.account, req.body, (err, reply) ->
      if err
        res.error err
      else
        res.status(201).json reply

  rest.put '/:id/status', (req, res) ->
    req.ticket.setStatusByAccount req.account, req.body.status, (err) ->
      if err
        res.error err
      else
        res.status(204).json req.ticket

exports.get '/list', (req, res) ->
  res.render 'ticket/list'

exports.get '/create', (req, res) ->
  res.render 'ticket/create'

exports.get '/view/:id', (req, res) ->
  res.render 'ticket/view'
