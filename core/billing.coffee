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

billing.runTimeBilling = (callback = ->) ->
  plans_billing_by_time = _.filter billing.plans, (plan) ->
    return plan.billing_trigger.time

  Account.find
    'plans':
      $in: plans_billing_by_time
  , (err, accounts) ->
    async.each accounts, (account, callback) ->
      billing.triggerBilling account, callback
    , callback

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
