{Router} = require 'express'
_ = require 'lodash'
Q = require 'q'

{Account, Ticket} = root
{requireAuthenticate} = require '../middleware'

module.exports = router = new Router()

router.use requireAuthenticate

router.param 'id', (req, res, next, ticket_id) ->
  Ticket.findById(ticket_id).done (ticket) ->
    unless req.ticket = ticket
      return next new Error 'ticket not found'

    unless ticket.hasMember req.account
      unless req.account.isAdmin()
        return next new Error 'ticket forbidden'

    next()
  , next

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
router.get '/', (req, res, next) ->
  Ticket.getTickets(req.account).done (tickets) ->
    res.json tickets
  , next

###
  Router: POST /tickets

  Response {Ticket}.
###
router.post '/', (req, res, next) ->
  Ticket.createTicket(req.account, req.body).done (ticket) ->
    res.status(201).json ticket
  , next

###
  Router: GET /tickets/:id

  Response {Ticket}.
###
router.get '/:id', (req, res, next) ->
  req.ticket.populateAccounts().done (ticket) ->
    res.json ticket
  , next

###
  Router: POST /tickets/:id/replies

  Response {Reply}.
###
router.post '/:id/replies', (req, res, next) ->
  req.ticket.createReply(req.account, req.body).done (reply) ->
    res.status(201).json reply
  , next

###
  Router: PUT /tickets/:id/status
###
router.put '/:id/status', (req, res, next) ->
  req.ticket.setStatusByAccount(req.account, req.body.status).done ->
    res.sendStatus 204
  , next
