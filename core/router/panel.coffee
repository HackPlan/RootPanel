_ = require 'underscore'

{express} = app.libs
{requireAuthenticate} = app.middleware
{Account, Financials} = app.models
{config} = app

module.exports = exports = express.Router()

exports.use requireAuthenticate

exports.use '/plan', do ->
  router = express.Router()

  router.param 'plan', (req, res, next, plan_name) ->
    req.plan = plan = app.plans.byName plan_name

    if plan
      next()
    else
      res.error 'plan_not_found'

  router.post '/:plan/join', (req, res) ->
    if req.account.balance <= config.billing.force_freeze.when_balance_below
      return res.error 'insufficient_balance'

    unless req.plan.join_freely
      return res.error 'cant_join_plan'

    req.plan.addMember(req.account).done ->
      res.sendStatus 204
    , res.error

  router.post '/:plan/leave', (req, res) ->
    req.plan.removeMember(req.account).done ->
      res.sendStatus 204
    , res.error

exports.get '/financials', (req, res) ->
  Q.all([
    rp.extends.payments.generateWidgets req
    Financials.getDepositLogs req.account, req: req, limit: 10
    Financials.getBillingLogs req.account, limit: 10
  ]).done ([payment_providers, deposit_logs, billing_logs]) ->
    res.render 'panel/financials',
      payment_providers: payment_providers
      deposit_logs: deposit_logs
      billing_logs: billing_logs
  , res.error

exports.get '/components', (req, res) ->
  res.render 'panel/components',
    component_providers: rp.extend.components.all()

exports.get '/', (req, res) ->
  app.applyHooks('view.panel.widgets', req.account,
    execute: 'generator'
  ).done (widgets_html) ->
    res.render 'panel',
      widgets_html: widgets_html
  , res.error
