config = require './config'

mAccount = require './model/account'
mBalance = require './model/balance'

exports.checkBilling = (account, callback) ->
  if (Date.now() - account.attribute.last_billing_at.getTime()) > 24 * 3600 * 1000
    exports.calcBilling account, false, callback
  else
    callback account

exports.calcBilling = (account, isForce, callback) ->
  amount = 0

  for planName in account.attribute.plans
    plan = config.plans[planName]

    price = plan.price / 30 / 24
    time = (Date.now() - account.attribute.last_billing_at.getTime()) / 1000 / 3600

    if isForce
      billing_time = Math.ceil time
    else
      billing_time = Math.floor time

    amount += price * billing_time

  unless amount
    callback account

  if isForce
    new_last_billing_at = new Date()
  else
    new_last_billing_at = new Date account.attribute.last_billing_at.getTime() + billing_time * 3600 * 1000

  modifier =
    $set:
      'attribute.last_billing_at': new_last_billing_at
    $inc:
      'attribute.balance': -amount

  if !account.attribute.arrears_at and account.attribute.balance < 0
    modifier.$set['attribute.arrears_at'] = new Date()

  if account.attribute.balance > 0
    modifier.$set['attribute.arrears_at'] = null

  mAccount.update _id: account._id, modifier, ->
    mBalance.create account, 'consumptions', -amount,
      plans: account.attribute.plans
      billing_time: billing_time
      is_force: isForce
      last_billing_at: last_billing_at
    , ->
      mAccount.findId account._id, (err, account) ->
        callback account

exports.calcRemainingTime = (account) ->
  price = 0

  for planName in account.attribute.plans
    plan = config.plans[planName]

    price += plan.price / 30 / 24

  return account.attribute.balance / price
