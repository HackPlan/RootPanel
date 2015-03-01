{express, _} = app.libs
{config, billing} = app
{requireAuthenticate} = app.middleware
{Account} = app.models

module.exports = exports = express.Router()

exports.use requireAuthenticate

{when_balance_below} = config.billing.force_freeze

exports.post '/join_plan', (req, res) ->
  {plan} = req.body

  unless billing.plans[plan]
    return res.error 'invalid_plan'

  if req.account.inPlan plan
    return res.error 'already_in_plan'

  if req.account.balance <= when_balance_below
    return res.error 'insufficient_balance'

  billing.joinPlan req.account, plan, (err) ->
    console.log err
    if err
      res.error err
    else
      res.status(204).json {}

exports.post '/leave_plan', (req, res) ->
  {plan} = req.body

  unless req.account.inPlan plan
    return res.error 'not_in_plan'

  billing.leavePlan req.account, plan, (err) ->
    if err
      res.error err
    else
      res.status(204).json {}
