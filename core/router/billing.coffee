{express, _} = app.libs
{config, billing} = app
{requireAuthenticate} = app.middleware
{Account} = app.models

module.exports = exports = express.Router()

exports.use requireAuthenticate

exports.post '/join_plan', (req, res) ->
  unless req.body.plan in _.keys(config.plans)
    return res.error 'invalid_plan'

  if req.body.plan in req.account.billing.plans
    return res.error 'already_in_plan'

  billing.triggerBilling req.account, (account) ->
    if account.billing.balance <= config.billing.force_freeze.when_balance_below
      return res.error 'insufficient_balance'

    billing.joinPlan req, account, req.body.plan, ->
      res.json {}

exports.post '/leave_plan', (req, res) ->
  unless req.body.plan in req.account.billing.plans
    return res.error 'not_in_plan'

  billing.triggerBilling req.account, (account) ->
    billing.leavePlan req, account, req.body.plan, ->
      res.json {}
