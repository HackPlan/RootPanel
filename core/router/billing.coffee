{express, _} = app.libs
{config, billing} = app
{requireAuthenticate} = app.middleware
{Plan} = app.interfaces
{Account} = app.models

module.exports = exports = express.Router()

exports.use requireAuthenticate

{when_balance_below} = config.billing.force_freeze

exports.post '/join_plan', (req, res) ->
  {plan} = req.body

  unless Plan.get plan
    return res.error 'invalid_plan'

  if plan in req.account.billing.plans
    return res.error 'already_in_plan'

  if req.account.billing.balance <= when_balance_below
    return res.error 'insufficient_balance'

  req.account.joinPlan plan, (err) ->
    res.error err if err
    res.status(204).json {}

exports.post '/leave_plan', (req, res) ->
  {plan} = req.body

  unless plan in req.account.billing.plans
    return res.error 'not_in_plan'

  req.account.leavePlan plan, (err) ->
    res.error err if err
    res.status(204).json {}
