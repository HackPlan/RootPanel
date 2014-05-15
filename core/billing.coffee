config = require './config'

mAccount = require './model/account'

exports.checkBilling = (account, callback) ->
  if (Date.now() - account.attribute.last_billing.getTime()) > 24 * 3600 * 1000
    exports.calcBilling account, callback
  else
    callback account

exports.calcBilling = (account, callback) ->
  amount = 0

  for planName in account.attribute.plans
    plan = config.plans[planName]

    price = plan.price / 30 / 24
    time = (Date.now() - account.attribute.last_billing.getTime()) / 1000 / 3600
    time = Math.ceil time
    amount += price * time

  modifier =
    $set:
      'attribute.last_billing': new Date()
    $inc:
      'attribute.balance': -amount

  if !account.attribute.arrears_at and account.attribute.balance < 0
    modifier['attribute.arrears_at'] = new Date()

  mAccount.update _id: account._id, modifier, {}, ->
    mAccount.findId account._id, (account) ->
      callback account

exports.calcRemainingTime = (account) ->
  price = 0

  for planName in account.attribute.plans
    plan = config.plans[planName]

    price += plan.price / 30 / 24

  return account.attribute.balance / price
