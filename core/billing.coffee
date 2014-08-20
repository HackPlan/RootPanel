config = require './../config'
plan = require './plan'

mAccount = require './model/account'
mBalance = require './model/balance'

exports.dailyBilling = ->
  mAccount.find
    'attribute.plans.0':
      $exists: true
  .toArray (err, accounts) ->
    for account in accounts
      exports.calcBilling account, false, ->

exports.dailyBilling()
setInterval exports.dailyBilling, 3600 * 1000

exports.checkBilling = (account, callback) ->
  if (Date.now() - account.attribute.last_billing_at.getTime()) > 24 * 3600 * 1000
    exports.calcBilling account, false, callback
  else
    callback account

exports.checkExpired = (account, callback) ->
  modifier =
    $set: {}

  callcallback = ->
    mAccount.update _id: account._id, modifier, ->
      mAccount.findId account._id, (err, account) ->
        callback account

  if account.attribute.balance > 0
    modifier.$set['attribute.arrears_at'] = null

  if account.attribute.balance < 0
    unless account.attribute.arrears_at
      modifier.$set['attribute.arrears_at'] = new Date()
    else
      if account.attribute.balance < -5
        return exports.forceUnsubscribe account, callcallback

      if Date.now() - account.attribute.arrears_at.getTime() > 15 * 24 * 3600 * 1000
        return exports.forceUnsubscribe account, callcallback

  callcallback()

exports.calcBilling = (account, isForce, callback) ->
  exports.checkExpired account, ->
    amount = 0

    for planName in _.filter(account.attribute.plans, (i) -> config.plans[i].price)
      plan_info = config.plans[planName]

      price = plan_info.price / 30 / 24
      time = (Date.now() - account.attribute.last_billing_at.getTime()) / 1000 / 3600

      if isForce
        billing_time = Math.ceil time
      else
        billing_time = Math.floor time

      amount += price * billing_time

    if amount <= 0
      return callback account

    if isForce
      new_last_billing_at = new Date()
    else
      new_last_billing_at = new Date account.attribute.last_billing_at.getTime() + billing_time * 3600 * 1000

    modifier =
      $set:
        'attribute.last_billing_at': new_last_billing_at
      $inc:
        'attribute.balance': -amount

    mAccount.update _id: account._id, modifier, ->
      mBalance.create account, 'billing', -amount,
        plans: account.attribute.plans
        billing_time: billing_time
        is_force: isForce
        last_billing_at: account.attribute.last_billing_at
      , ->
        mAccount.findId account._id, (err, account) ->
          callback account

exports.forceUnsubscribe = (account, callback) ->
  async.mapSeries account.attribute.plans, (plan_name, callback) ->
    mAccount.findId account._id, (err, account) ->
      plan.leavePlan account, plan_name, callback
  , ->
    callback()

exports.calcRemainingTime = (account) ->
  price = 0

  for planName in _.filter(account.attribute.plans, (i) -> config.plans[i].price)
    plan_info = config.plans[planName]

    price += plan_info.price / 30 / 24

  return account.attribute.balance / price
