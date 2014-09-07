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
  forceLeaveAllPlans = (callback) ->
    async.eachSeries account.billing.plans, (plan_name, callback) ->
      mAccount.findOne {_id: account._id}, (err, account) ->
        plan.leavePlan account, plan_name, callback
    , ->
      mAccount.findOne {_id: account._id}, (err, account) ->
        callback account

  is_force = do ->
    if account.attribute.balance < config.billing.force_freeze.when_balance_below
      return true

    if Date.now() > account.attribute.arrears_at.getTime() + config.billing.force_freeze.when_arrears_above
      return true

    return false

  if is_force
    return forceLeaveAllPlans callback

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

    billing_unit_count = (Date.now() - last_billing_at.getTime()) / plan_info.billing_by_time.unit

    if is_force
      billing_unit_count = Math.ceil billing_unit_count
      new_last_billing_at = new Date()
    else
      billing_unit_count = Math.floor billing_unit_count
      new_last_billing_at = new Date last_billing_at.getTime() + billing_unit_count * plan_info.billing_by_time.unit

    amount = billing_unit_count * plan_info.billing_by_time.price

    callback null,
      name: plan_name
      billing_unit_count: billing_unit_count
      last_billing_at: new_last_billing_at
      amount_inc: -amount

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


        callback account

exports.forceBilling = (account, plan_name, callback) ->
  plan_info = config.plans[plan_name]

  unless plan_info.billing_by_time
    return callback()





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
