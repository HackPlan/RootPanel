_ = require 'underscore'
Q = require 'q'

{express} = app.libs
{requireAdminAuthenticate} = app.middleware
{Account, Ticket, Financials, CouponCode} = app.models
{config} = app

module.exports = exports = express.Router()

exports.use requireAdminAuthenticate

exports.get '/', (req, res) ->
  Q.all([
    Account.find()
    rp.applyHooks 'view.admin.sidebars', req.account, req: req, execute: 'generator'
  ]).done ([accounts, sidebars_html]) ->
    res.render 'admin',
      accounts: accounts
      sidebars_html: sidebars_html
  , res.error

exports.get '/tickets', (req, res) ->
  Ticket.getTicketsGroupByStatus(
    opening:
      limit: 10
    finished:
      limit: 10
    closed:
      limit: 10
  ).done (tickets) ->
    res.render 'ticket/list', tickets
  , res.error

exports.post '/coupons/generate', (req, res) ->
  CouponCode.createCodes(req.body, req.body.count).done (coupons) ->
    res.json coupons
  , res.error

exports.use '/user', do ->
  router = express.Router()

  router.param 'id', (req, res, next, user_id) ->
    Account.findById(user_id).then (user) ->
      _.extend req,
        user: user

      unless user
        return res.error 404, 'user_not_found'

      next()

    .catch res.error

  router.param 'plan', (req, res, next, plan_name) ->
    req.plan = plan = app.plans.byName plan_name

    if plan
      next()
    else
      res.error 'plan_not_found'

  router.get '/:id', (req, res) ->
    res.json req.user.pick()

  router.post '/:id/plan/:plan/join', (req, res) ->
    req.plan.addMember(req.account).done ->
      res.sendStatus 204
    , res.erro

  router.post '/:id/plan/:plan/leave', (req, res) ->
    req.plan.removeMember(req.account).done ->
      res.sendStatus 204
    , res.error

  router.post '/:id/deposits/create', (req, res) ->
    Financials.createDepositRequest(req.user, req.body.amount,
      provider: req.body.provider
      order_id: req.body.order_id
    ).then (financial) ->
      if req.body.status
        financial.updateStatus req.body.status
    .done ->
      res.sendStatus 204
    , res.error

  router.delete '/:id', (req, res) ->
    unless _.isEmpty account.plans
      return res.error 'already_in_plan'

    unless account.balance <= 0
      return res.error 'balance_not_empty'

    req.user.remove().done ->
      res.sendStatus 204
    , res.error
