{config, pluggable, logger} = app
{async, _} = app.libs
{Account, Financials, Component} = app.models

billing = exports

billing.start = ->
  Account.find
    'billing.plans.0':
      $exists: true
  , (err, accounts) ->
    async.each accounts, (account, callback) ->
      exports.triggerBilling account, ->
        callback()
    , ->
      callback()

# @param callback(account)
exports.triggerBilling = (account, callback) ->
  async.map account.billing.plans, (plan_name, callback) ->
    exports.generateBilling account, plan_name, (result) ->
      callback null, result

  , (err, result) ->
    billing_reports = _.compact result

    if _.isEmpty billing_reports
      if exports.isForceFreeze account
        return exports.forceLeaveAllPlans account, callback
      else
        return callback account

    modifier =
      $set: {}
      $inc:
        'billing.balance': 0

    for report in billing_reports
      modifier.$set["billing.last_billing_at.#{report.plan_name}"] = report.last_billing_at
      modifier.$inc['billing.balance'] += report.amount_inc

    if account.billing.balance > 0
      if account.billing.arrears_at
        modifier.$set['billing.arrears_at'] = null
    else if account.billing.balance < 0
      unless account.billing.arrears_at
        modifier.$set['billing.arrears_at'] = new Date()

    Account.findByIdAndUpdate account._id, modifier, (err, account) ->
      logger.error err if err

      Financials.create
        account_id: account._id
        type: 'billing'
        amount: modifier.$inc['billing.balance']
        payload: _.indexBy billing_reports, 'plan_name'
      , ->
        if exports.isForceFreeze account
          exports.forceLeaveAllPlans account, callback
        else
          callback account

exports.generateBilling = (account, plan_name, callback) ->
  plan_info = config.plans[plan_name]

  unless plan_info.billing_by_time
    return callback()

  last_billing_at = account.billing.last_billing_at[plan_name]

  unless last_billing_at < new Date()
    return callback()

  billing_time_range = (Date.now() + plan_info.billing_by_time.unit) - last_billing_at.getTime()
  billing_unit_count = Math.floor billing_time_range / plan_info.billing_by_time.unit

  new_last_billing_at = new Date last_billing_at.getTime() + billing_unit_count * plan_info.billing_by_time.unit
  amount = billing_unit_count * plan_info.billing_by_time.price

  callback
    plan_name: plan_name
    billing_unit_count: billing_unit_count
    last_billing_at: new_last_billing_at
    amount_inc: -amount

exports.isForceFreeze = (account) ->
  if _.isEmpty account.billing.plans
    return false

  if account.billing.balance < config.billing.force_freeze.when_balance_below
    return true

  if account.billing.arrears_at
    if Date.now() > account.billing.arrears_at.getTime() + config.billing.force_freeze.when_arrears_above
      return true

  return false

# @param callback(account)
exports.forceLeaveAllPlans = (account, callback) ->
  async.eachSeries account.billing.plans, (plan_name, callback) ->
    exports.leavePlan {}, account, plan_name, callback
  , ->
    Account.findById account._id, (err, account) ->
      callback account

exports.calcResourcesLimit = (plans) ->
  limit = {}

  for plan_name in plans
    if config.plans[plan_name].resources
      for k, v of config.plans[plan_name].resources
        limit[k] ?= 0
        limit[k] += v

  return limit
