{_, express} = app.libs
{requireAuthenticate} = app.middleware
{Account, Ticket} = app.models
{config, logger} = app

module.exports = exports = express.Router()

exports.use requireAuthenticate

loadTicket = (req, res, next, ticket_id) ->
  Ticket.findById(ticket_id).then (ticket) ->
    _.extend req,
      ticket: ticket

    unless ticket
      return res.error 404, 'ticket_not_found'

    unless ticket.hasMember req.account
      unless req.account.isAdmin()
        return res.error 403, 'ticket_forbidden'

  .done next, res.error

exports.param 'id', loadTicket

exports.use '/rest', do ->
  rest = new express.Router mergeParams: true
  rest.param 'id', loadTicket

  rest.get '/', (req, res) ->
    Ticket.getTickets(req.account).done (tickets) ->
      res.json tickets
    , res.error

  rest.post '/', (req, res) ->
    Ticket.createTicket(req.account, req.body).done (ticket) ->
      res.status(201).json ticket
    , res.error

  rest.get '/:id', (req, res) ->
    req.ticket.populateAccounts().done (ticket) ->
      res.json ticket
    , res.error

  rest.put '/:id', (req, res) ->

  rest.patch '/:id', (req, res) ->

  rest.delete '/:id', (req, res) ->

  rest.post '/:id/replies', (req, res) ->
    req.ticket.createReply(req.account, req.body).done (reply) ->
      res.status(201).json reply
    , res.error

  rest.put '/:id/status', (req, res) ->
    req.ticket.setStatusByAccount(req.account, req.body.status).done ->
      res.sendStatus 204
    , res.error

exports.get '/list', (req, res) ->
  res.render 'ticket/list'

exports.get '/create', (req, res) ->
  res.render 'ticket/create'

exports.get '/view/:id', (req, res) ->
  res.render 'ticket/view'
