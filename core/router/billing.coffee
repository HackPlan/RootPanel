express = require 'express'
_ = require 'underscore'

{config, pluggable, billing} = app
{requireAuthenticate} = require './../middleware'

mAccount = require '../model/account'

module.exports = exports = express.Router()

exports.post '/join_plan', requireAuthenticate, (req, res) ->
  unless req.body.plan in _.keys(config.plans)
    return res.error 'invaild_plan'

  if req.body.plan in req.account.billing.plans
    return res.error 'already_in_plan'

  plan_info = config.plans[req.body.plan]

  billing.triggerBilling req.account, (account) ->
    if account.billing.balance < config.billing.force_freeze.when_balance_below
      return res.error 'insufficient_balance'

    billing.joinPlan account, req.body.plan, ->
      res.json {}

exports.post '/leave_plan', requireAuthenticate, (req, res) ->
  unless req.body.plan in req.account.billing.plans
    return res.error 'not_in_plan'

  billing.generateBilling req.account, req.body.plan, {is_force: true}, (account) ->
    billing.leavePlan account, req.body.plan, ->
      res.json {}
