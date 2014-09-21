express = require 'express'
_ = require 'underscore'

{config, pluggable, billing} = app
{requireAuthenticate} = require './../middleware'

mAccount = require '../model/account'

module.exports = exports = express.Router()

exports.post '/join_plan', requireAuthenticate, (req, res) ->
  unless req.body.plan in _.keys(config.plans)
    return res.error 'invaild_plan'

  if req.body.plan in req.account.attribute.plans
    return res.error 'already_in_plan'

  plan_info = config.plans[req.body.plan]

  billing.calcBilling req.account, true, (account) ->
    if plan_info.price and account.attribute.balance <= 0
      return res.error 'insufficient_balance'

    if account.attribute.balance < 0
      return res.error 'insufficient_balance'

    plan.joinPlan account, req.body.plan, ->
      res.json {}

exports.post '/leave_plan', requireAuthenticate, (req, res) ->
  unless req.body.plan in req.account.attribute.plans
    return res.error 'not_in_plan'

  billing.calcBilling req.account, true, (account) ->
    plan.leavePlan account, req.body.plan, ->
      res.json {}
