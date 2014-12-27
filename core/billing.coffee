{config, pluggable, logger} = app
{async, _} = app.libs
{Account, Financials, Component} = app.models

process.nextTick ->
  {Account} = app.models

Plan = require './interface/Plan'

billing = _.extend exports,
  plans: {}

billing.initPlans = ->
  for name, info of config.plans
    billing.plans[name] = new Plan _.extend info,
      name: name

  app.on 'app.started', ->
    billing.runTimeBilling ->
      setInterval billing.runTimeBilling, 3600 * 1000

billing.triggerBilling = (account, callback) ->
  async.each account.plans, (plan, callback) ->
    billing.plans[plan].triggerBilling account, callback
  , (err) ->
    return callback err if err

    if billing.isForceFreeze account
      account.leaveAllPlans callback
    else
      callback err, account

billing.acceptUsagesBilling = (account, trigger_name, volume, callback) ->
  plan_names = _.filter billing.plans, (plan) ->
    return plan.billing_trigger[trigger_name] and account.inPlan plan

  async.each plan_names, (plan_name, callback) ->
    billing.plans[plan_name].acceptUsagesBilling account, trigger_name, volume, callback
  , callback

billing.runTimeBilling = (callback = ->) ->
  plan_names = _.filter billing.plans, (plan) ->
    return plan.billing_trigger.time

  Account.find
    'plans':
      $in: plan_names
  , (err, accounts) ->
    async.each accounts, (account, callback) ->
      billing.triggerBilling account, callback
    , callback

# @param callback(err, account)
billing.checkArrearsAt = (account, callback) ->
  if account.balance < 0 and !account.arrears_at
    Account.findByIdAndUpdate account._id,
      $set:
        arrears_at: new Date()
    , callback
  else if account.balance > 0 and account.arrears_at
    Account.findByIdAndUpdate account._id,
      $set:
        arrears_at: null
    , callback
  else
    callback null, callback

billing.isForceFreeze = (account) ->
  {force_freeze} = config.billing

  if _.isEmpty account.plans
    return false

  if account.balance < force_freeze.when_balance_below
    return true

  if account.arrears_at
    if Date.now() > account.arrears_at.getTime() + force_freeze.when_arrears_above
      return true

  return false
