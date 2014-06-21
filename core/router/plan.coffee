config = require '../config'
plugin = require '../plugin'
billing = require '../billing'
plan = require '../plan'
{requestAuthenticate} = require './middleware'

mAccount = require '../model/account'

module.exports = exports = express.Router()

exports.post '/subscribe', requestAuthenticate, (req, res) ->
  unless req.body.plan in _.keys(config.plans)
    return res.error 'invaild_plan'

  if req.body.plan in req.account.attribute.plans
    return res.error 'already_in_plan'

  billing.calcBilling req.account, true, (account) ->
    if account.attribute.balance <= 0
      return res.error 'insufficient_balance'

    plan.joinPlan account, req.body.plan, ->
      res.json {}

exports.post '/unsubscribe', requestAuthenticate, (req, res) ->
  unless req.body.plan in req.account.attribute.plans
    return res.error 'not_in_plan'

  billing.calcBilling req.account, true, (account) ->
    plan.leavePlan account, req.body.plan, ->
      res.json {}
