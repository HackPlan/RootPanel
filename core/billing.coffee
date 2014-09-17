async = require 'async'
_ = require 'underscore'

mAccount = require './model/account'
mBalance = require './model/balance_log'

config = require '../config'

exports.cyclicalBilling = (callback) ->
  mAccount.find
    'attribute.plans.0':
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

# @param callback(account)
exports.triggerBilling = (account, callback) ->
  forceLeaveAllPlans = (callback) ->
    async.eachSeries account.billing.plans, (plan_name, callback) ->
      mAccount.findOne {_id: account._id}, (err, account) ->
        plan.leavePlan account, plan_name, callback
    , ->
      mAccount.findOne {_id: account._id}, (err, account) ->
        callback account

  is_force = do ->
    if account.billing.balance < config.billing.force_freeze.when_balance_below
      return true

    if account.billing.arrears_at and Date.now() > account.billing.arrears_at.getTime() + config.billing.force_freeze.when_arrears_above
      return true

    return false

  async.each account.billing.plans, (plan_name, callback) ->
    exports.generateBilling account, plan_name, is_force, (result) ->
      callback null, result

  , (err, result) ->
    result = _.compact result

    if _.isEmpty result
      return callback account

    modifier =
      $set: {}
      $inc:
        'billing.balance': 0

    for item in result
      modifier.$set["billing.last_billing_at.#{item.name}"] = item.last_billing_at
      modifier.$inc['billing.balance'] += item.amount_inc

    if account.billing.balance > 0
      if account.billing.arrears_at
        modifier.$set['billing.arrears_at'] = null
    else if account.billing.balance < 0
      unless account.billing.arrears_at
        modifier.$set['billing.arrears_at'] = new Date()

    mAccount.findAndModify {_id: account._id}, null, modifier, {new: true}, (err, account) ->
      mBalance.create account, 'billing', modifier.$inc['billing.balance'],
        plans: _.indexBy result, 'name'
      , ->
        if is_force
          return forceLeaveAllPlans callback
        else
          callback account

exports.generateBilling = (account, plan_name, is_force, callback) ->
  plan_info = config.plans[plan_name]

  unless plan_info.billing_by_time
    return callback()

  last_billing_at = account.billing.last_billing_at[plan_name]

  if last_billing_at
    next_billing_at = new Date last_billing_at.getTime() + plan_info.billing_by_time.unit * plan_info.billing_by_time.min_billing_unit
  else
    last_billing_at = new Date()

  unless last_billing_at and next_billing_at > new Date()
    return callback()

  billing_unit_count = (Date.now() - last_billing_at.getTime()) / plan_info.billing_by_time.unit

  if is_force
    billing_unit_count = Math.ceil billing_unit_count
    new_last_billing_at = new Date()
  else
    billing_unit_count = Math.floor billing_unit_count
    new_last_billing_at = new Date last_billing_at.getTime() + billing_unit_count * plan_info.billing_by_time.unit

  amount = billing_unit_count * plan_info.billing_by_time.price

  callback
    name: plan_name
    billing_unit_count: billing_unit_count
    last_billing_at: new_last_billing_at
    amount_inc: -amount

exports.joinPlan = (account, plan, callback) ->
  mAccount.joinPlan account, plan, ->
    async.each config.plans[plan].services, (serviceName, callback) ->
      if serviceName in account.attribute.services
        return callback()

      mAccount.findAndModify _id: account._id, {},
        $addToSet:
          'attribute.services': serviceName
      ,
        new: true
      , (err, account)->
        (pluggable.get serviceName).service.enable account, ->
          callback()

    , ->
      callback()

exports.leavePlan = (account, plan, callback) ->
  mAccount.leavePlan account, plan, ->
    async.each config.plans[plan].services, (serviceName, callback) ->
      stillInService = do ->
        for item in _.without(account.attribute.plans, plan)
          if serviceName in config.plans[item].services
            return true

        return false

      if stillInService
        callback()
      else
        modifier =
          $pull:
            'attribute.services': serviceName
          $unset: {}

        modifier['$unset']["attribute.plugin.#{serviceName}"] = ''

        mAccount.update _id: account._id, modifier, (err) ->
          throw err if err
          (pluggable.get serviceName).service.delete account, ->
            callback()

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
