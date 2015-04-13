{Router} = require 'express'
_ = require 'lodash'
Q = require 'q'

{Account, Ticket} = root

module.exports = router = new Router()

router.use root.middleware.requireAuthenticate

router.param 'id', (req, res, next, ticket_id) ->
  Ticket.findById(ticket_id).done (ticket) ->
    unless req.ticket = ticket
      return res.error 404, 'ticket_not_found'

    unless ticket.hasMember req.account
      unless req.account.isAdmin()
        return res.error 403, 'ticket_forbidden'

    next()
  , res.error

###
  Router: GET /tickets/list

  Response HTML.
###
router.get '/list', (req, res) ->
  res.render 'ticket/list'

###
  Router: GET /tickets/create

  Response HTML.
###
router.get '/create', (req, res) ->
  res.render 'ticket/create'

###
  Router: GET /tickets/:id/view

  Response HTML.
###
router.get '/:id/view', (req, res) ->
  res.render 'ticket/view'

###
  Router: GET /tickets

  Response {Array} of {Ticket}.
###
router.get '/', (req, res) ->
  Ticket.getTickets(req.account).done (tickets) ->
    res.json tickets
  , res.error

###
  Router: POST /tickets

  Response {Ticket}.
###
router.post '/', (req, res) ->
  Ticket.createTicket(req.account, req.body).done (ticket) ->
    res.status(201).json ticket
  , res.error

###
  Router: GET /tickets/:id

  Response {Ticket}.
###
router.get '/:id', (req, res) ->
  req.ticket.populateAccounts().done (ticket) ->
    res.json ticket
  , res.error

###
  Router: POST /tickets/:id/replies

  Response {Reply}.
###
router.post '/:id/replies', (req, res) ->
  req.ticket.createReply(req.account, req.body).done (reply) ->
    res.status(201).json reply
  , res.error

###
  Router: PUT /tickets/:id/status
###
router.put '/:id/status', (req, res) ->
  req.ticket.setStatusByAccount(req.account, req.body.status).done ->
    res.sendStatus 204
  , res.error
