{config, pluggable, logger} = app
{async, _} = app.libs
{Account, Financials} = app.models

billing = exports
billing.plans = {}

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

exports.joinPlan = (req, account, plan_name, callback) ->
  original_account = account
  plan_info = config.plans[plan_name]

  modifier =
    $addToSet:
      'billing.plans': plan_name
      'billing.services':
        $each: plan_info.services
    $set:
      'resources_limit': exports.calcResourcesLimit _.union account.billing.plans, [plan_name]

  modifier.$set["billing.last_billing_at.#{plan_name}"] = new Date()

  Account.findByIdAndUpdate account._id, modifier, (err, account) ->
    logger.error err if err

    async.each _.difference(account.billing.services, original_account.billing.services), (service_name, callback) ->
      async.each pluggable.selectHook("service.#{service_name}.enable"), (hook, callback) ->
        hook.filter account, callback
      , callback
    , ->
      unless _.isEqual original_account.resources_limit, account.resources_limit
        async.each pluggable.selectHook('account.resources_limit_changed'), (hook, callback) ->
          hook.filter account, callback
        , callback
      else
        callback()

exports.leavePlan = (req, account, plan_name, callback) ->
  leaved_services = _.reject account.billing.services, (service_name) ->
    for item in _.without(account.billing.plans, plan_name)
      if service_name in config.plans[item].services
        return true

    return false

  original_account = account

  modifier =
    $pull:
      'billing.plans': plan_name
    $pullAll:
      'billing.services': leaved_services
    $set:
      'resources_limit': exports.calcResourcesLimit _.without account.billing.plans, plan_name
    $unset: {}

  modifier.$unset["billing.last_billing_at.#{plan_name}"] = true

  Account.findByIdAndUpdate account._id, modifier, (err, account) ->
    logger.error err if err

    async.each leaved_services, (service_name, callback) ->
      async.each pluggable.selectHook("service.#{service_name}.disable"), (hook, callback) ->
        hook.filter account, callback
      , callback
    , ->
      unless _.isEqual original_account.resources_limit, account.resources_limit
        async.each pluggable.selectHook('account.resources_limit_changed'), (hook, callback) ->
          hook.filter account, callback
        , callback
      else
        callback()

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

exports.initPlans = ->
  for name, info in config.plans
    plan = new Plan info
    exports.plans[name] = plan

exports.Plan = Plan = class Plan
  info: null
  name: null

  constructor: (@info) ->
    @name = @info.name
