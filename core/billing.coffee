{config, plan} = app
{mAccount, mBalance} = app.models

exports.triggerBilling = (account, callback) ->




exports.cyclicalBilling = ->
  mAccount.find
    'attribute.plans.0':
      $exists: true
  .toArray (err, accounts) ->
    for account in accounts
      exports.calcBilling account,
        is_force: false
      , ->

exports.checkBilling = (account, callback) ->
  if Date.now() > account.attribute.last_billing_at.getTime() + config.billing.daily_billing_cycle
    exports.calcBilling account,
      is_force: false
    , callback
  else
    callback account

exports.checkExpired = (account, callback) ->
  modifier =
    $set: {}

  callback_back = ->
    if _.isEmpty modifier.$set
      return callback account

    mAccount.findAndModify _id: account._id, {}, modifier, new: true, (err, account) ->
      callback account

  if account.attribute.balance > 0
    modifier.$set['attribute.arrears_at'] = null

  if account.attribute.balance < 0
    if account.attribute.balance < config.billing.force_unsubscribe.when_balance_below
      return exports.forceUnsubscribe account, callback_back

    unless account.attribute.arrears_at
      account.attribute.arrears_at = modifier.$set['attribute.arrears_at'] = new Date()

    if Date.now() > account.attribute.arrears_at.getTime() + config.billing.force_unsubscribe.when_arrears_above
      return exports.forceUnsubscribe account, callback_back

  callback_back()

exports.calcBilling = (account, options, callback) ->
  {is_force} = options

  exports.checkExpired account, (account) ->
    amount = 0

    for planName in _.filter(account.attribute.plans, (i) -> config.plans[i].price)
      plan_info = config.plans[planName]

      price = plan_info.price / 30 / 24
      time_hour = (Date.now() - account.attribute.last_billing_at.getTime()) / 1000 / 3600

      if is_force
        billing_time_hour = Math.ceil time_hour
      else
        billing_time_hour = Math.floor time_hour

      amount += price * billing_time_hour

    if amount <= 0
      return callback account

    if is_force
      new_last_billing_at = new Date()
    else
      new_last_billing_at = new Date account.attribute.last_billing_at.getTime() + billing_time_hour * 3600 * 1000

    # TODO: 付费套餐与非付费套餐并存的情况

    modifier =
      $set:
        'attribute.last_billing_at': new_last_billing_at
      $inc:
        'attribute.balance': -amount

    mAccount.findAndModify _id: account._id, {}, modifier, new: true, (err, account) ->
      mBalance.create account, 'billing', -amount,
        plans: account.attribute.plans
        billing_time: billing_time_hour
        is_force: is_force
        last_billing_at: account.attribute.last_billing_at
      , ->
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

exports.cyclicalBilling()
setInterval exports.cyclicalBilling, config.billing.cyclical_billing
