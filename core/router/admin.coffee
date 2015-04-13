{Router} = require 'express'
_ = require 'lodash'
Q = require 'q'

{Account, Ticket, Financials, CouponCode} = root

module.exports = router = new Router()

router.use root.middleware.requireAdminAuthenticate

###
  Router: GET /admin/dashboard

  Response HTML.
###
router.get '/dashboard', (req, res) ->
  Q.all([
    Account.find()
  ]).done ([accounts]) ->
    res.render 'admin',
      accounts: accounts
  , res.error

###
  Router: GET /admin/tickets/list

  Response HTML.
###
router.get '/tickets/list', (req, res) ->
  Ticket.getTicketsGroupByStatus
    opening:
      limit: 10
    finished:
      limit: 10
    closed:
      limit: 10
  .done (tickets) ->
    res.render 'ticket/list', tickets
  , res.error

###
  Router: POST /admin/coupons/generate

  Response {Array} of {CouponCode}.
###
router.post '/coupons/generate', (req, res) ->
  CouponCode.createCodes(req.body, req.body.count).done (coupons) ->
    res.json coupons
  , res.error

router.use '/users', do (router = new Router) ->
  router.param 'id', (req, res, next, user_id) ->
    Account.findById(user_id).then (user) ->
      if req.user = user
        next
      else
        res.error 404, 'user_not_found'
    .catch res.error

  router.param 'plan', (req, res, next, plan_name) ->
    if req.plan = root.billing.byName plan_name
      next()
    else
      res.error 'plan_not_found'

  ###
    Router: GET /admin/users/:id

    Response {Account}.
  ###
  router.get '/:id', (req, res) ->
    res.json req.user.pick 'admin'

  ###
    Router: GET /admin/users/:id/plans/join
  ###
  router.post '/:id/plans/join', (req, res) ->
    req.plan.addMember(req.account).done ->
      res.sendStatus 204
    , res.erro

  ###
    Router: GET /admin/users/:id/plans/leave
  ###
  router.post '/:id/plans/leave', (req, res) ->
    req.plan.removeMember(req.account).done ->
      res.sendStatus 204
    , res.erro

  ###
    Router: POST /admin/users/:id/deposits/create

    Request {Object}

      * `amount` {Number}
      * `provider` {String}
      * `orderId` {String}
      * `status` (optional) {String}

    Response {Financials}.
  ###
  router.post '/:id/deposits/create', (req, res) ->
    Financials.createDepositRequest(req.user, req.body.amount,
      provider: req.body.provider
      order_id: req.body.orderId
    ).tap (financial) ->
      if req.body.status
        financial.updateStatus req.body.status
    .done (financial) ->
      res.json financial
    , res.error

  ###
    Router: DELETE /admin/users/:id
  ###
  router.delete '/:id', (req, res) ->
    unless _.isEmpty req.user.plans
      return res.error 'already_in_plan'

    unless req.user.balance <= 0
      return res.error 'balance_not_empty'

    req.user.remove().done ->
      res.sendStatus 204
    , res.error
