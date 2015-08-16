{Router} = require 'express'
_ = require 'lodash'
Q = require 'q'

{Account, Ticket, Financials, CouponCode, Component} = root
{requireAdminAuthenticate} = require '../middleware'

module.exports = router = new Router()

router.use requireAdminAuthenticate

###
  Router: GET /admin/dashboard

  Response HTML.
###
router.get '/dashboard', (req, res, next) ->
  Q.all([
    Account.find()
    Component.find()
    Ticket.getTicketsGroupByStatus
      opening:
        limit: 10
      finished:
        limit: 10
      closed:
        limit: 10
  ]).done ([accounts, components, tickets]) ->
    res.render 'admin',
      accounts: accounts
      components: components
      tickets: tickets
  , next

###
  Router: POST /admin/coupons/generate

  Response {Array} of {CouponCode}.
###
router.post '/coupons/generate', (req, res, next) ->
  CouponCode.createCodes(req.body, req.body.count).done (coupons) ->
    res.json coupons
  , next

router.use '/users', do (router = new Router) ->
  router.param 'id', (req, res, next, user_id) ->
    Account.findById(user_id).then (user) ->
      if req.user = user
        next
      else
        next new Error 'user not found'
    .catch next

  router.param 'plan', (req, res, next, plan_name) ->
    if req.plan = root.billing.byName plan_name
      next()
    else
      next new Error 'plan not found'

  ###
    Router: GET /admin/users/:id

    Response {Account}.
  ###
  router.get '/:id', (req, res) ->
    res.json req.user.pick 'admin'

  ###
    Router: GET /admin/users/:id/plans/join
  ###
  router.post '/:id/plans/join', (req, res, next) ->
    req.plan.addMember(req.account).done ->
      res.sendStatus 204
    , next

  ###
    Router: GET /admin/users/:id/plans/leave
  ###
  router.post '/:id/plans/leave', (req, res, next) ->
    req.plan.removeMember(req.account).done ->
      res.sendStatus 204
    , next

  ###
    Router: POST /admin/users/:id/deposits/create

    Request {Object}

      * `amount` {Number}
      * `provider` {String}
      * `orderId` {String}
      * `status` (optional) {String}

    Response {Financials}.
  ###
  router.post '/:id/deposits/create', (req, res, next) ->
    Financials.createDepositRequest(req.user, req.body.amount,
      provider: req.body.provider
      order_id: req.body.orderId
    ).tap (financial) ->
      if req.body.status
        financial.updateStatus req.body.status
    .done (financial) ->
      res.json financial
    , next

  ###
    Router: DELETE /admin/users/:id
  ###
  router.delete '/:id', (req, res, next) ->
    unless _.isEmpty req.user.plans
      return next new Error 'already in plan'

    unless req.user.balance <= 0
      return next new Error 'balance not empty'

    req.user.remove().done ->
      res.sendStatus 204
    , next
