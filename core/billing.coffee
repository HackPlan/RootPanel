{config, plan} = app
{mAccount, mBalance} = app.models

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

exports.cyclicalBilling ->
  setInterval ->
    exports.cyclicalBilling ->
  , config.billing.billing_cycle

# @param callback(account)
exports.triggerBilling = (account, callback) ->
  modifier =
    $inc:
      'attribute.balance': 0

  async.each account.billing.plans, (plan_name, callback) ->
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

    billing_unit_count = Math.floor (Date.now() - last_billing_at.getTime()) / plan_info.billing_by_time.unit

    new_last_billing_at = new Date last_billing_at.getTime() + billing_unit_count * plan_info.billing_by_time.unit
    amount = billing_unit_count * plan_info.billing_by_time.price

    callback null,
      name: plan_name
      last_billing_at: new_last_billing_at
      amount_inc: -amount

  , (err, result) ->
    result = _.compact result

    if _.isEmpty result
      return callback()

    modifier =
      $set: {}
      $inc:
        'billing.balance': 0

    for item in result
      modifier.$set["billing.last_billing_at.#{item.name}"] = item.last_billing_at
      modifier.$inc['billing.balance'] += item.amount_inc

    mAccount.findAndModify {_id: account._id}, null, modifier, new: true, (err, account) ->
      mBalance.create account, 'billing', modifier.$inc['billing.balance'],
        plans: _.pluck result, 'name'
        billing_time: billing_time_hour
        is_force: is_force
        last_billing_at: account.attribute.last_billing_at
      , ->
        callback account

    callback()

exports.forceBilling = (account, plan_name, callback) ->


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
