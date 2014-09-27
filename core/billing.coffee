async = require 'async'
_ = require 'underscore'

mAccount = require './model/account'
mBalance = require './model/balance_log'

config = require '../config'
pluggable = require './pluggable'

exports.cyclicalBilling = (callback) ->
  mAccount.find
    'billing.plans.0':
      $exists: true
  .toArray (err, accounts) ->
    async.each accounts, (account, callback) ->
      exports.triggerBilling account, ->
        callback()
    , ->
      callback()

exports.run = ->
  exports.cyclicalBilling ->
    setInterval ->
      exports.cyclicalBilling ->
    , config.billing.billing_cycle

exports.forceLeaveAllPlans = (account, callback) ->
  async.eachSeries account.billing.plans, (plan_name, callback) ->
    exports.leavePlan account, plan_name, callback
  , ->
    mAccount.findOne {_id: account._id}, (err, account) ->
      callback account

exports.isForceFreeze = (account) ->
  if account.billing.balance < config.billing.force_freeze.when_balance_below
    return true

  if account.billing.arrears_at
    if Date.now() > account.billing.arrears_at.getTime() + config.billing.force_freeze.when_arrears_above
      return true

  return false

# @param callback(account)
exports.triggerBilling = (account, callback) ->
  async.map account.billing.plans, (plan_name, callback) ->
    exports.generateBilling account, plan_name, (result) ->
      callback null, result

  , (err, result) ->
    billing_reports = _.compact result

    if _.isEmpty billing_reports
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

    mAccount.findAndModify {_id: account._id}, null, modifier, {new: true}, (err, account) ->
      mBalance.create account, 'billing', modifier.$inc['billing.balance'], _.indexBy(billing_reports, 'plan_name'), ->
        if exports.isForceFreeze account
          exports.forceLeaveAllPlans account, ->
            callback()
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

exports.joinPlan = (account, plan_name, callback) ->
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

  mAccount.findAndModify {_id: account._id}, null, modifier,
    new: true
  , (err, account) ->
    async.each _.difference(account.billing.services, original_account.billing.services), (service_name, callback) ->
      async.each pluggable.selectHook(account, "service.#{service_name}.enable"), (hook, callback) ->
        hook.action account, callback
      , callback
    , ->
      callback()

exports.leavePlan = (account, plan_name, callback) ->
  leaved_services = _.reject account.billing.services, (service_name) ->
    for item in _.without(account.billing.plans, plan_name)
      if service_name in config.plans[item].services
        return true

    return false

  modifier =
    $pull:
      'billing.plans': plan_name
    $pullAll:
      'billing.services': leaved_services
    $set:
      'resources_limit': exports.calcResourcesLimit _.without account.billing.plans, plan_name
    $unset: {}

  modifier.$unset["billing.last_billing_at.#{plan_name}"] = true

  mAccount.findAndModify {_id: account._id}, null, modifier,
    new: true
  , (err, account) ->
    async.each leaved_services, (service_name, callback) ->
      async.each pluggable.selectHook(account, "service.#{service_name}.disable"), (hook, callback) ->
        hook.action account, callback
      , callback
    , ->
      callback()

exports.calcResourcesLimit = (plans) ->
  limit = {}

  for plan_name in plans
    if config.plans[plan_name].resources
      for k, v of config.plans[plan_name].resources
        limit[k] ?= 0
        limit[k] += v

  return limit
