{_} = app.libs
{config, logger} = app
{Account, Financials} = app.models

process.nextTick ->
  {Account, Financials} = app.models

{available_plugins} = config.plugin

module.exports = class Plan
  constructor: (info) ->
    _.extend @, info

    @available_components ?= {}

    for component_type, info of @available_components
      unless component_type in available_plugins
        err = new Error "Plan:#{@name} include unknown Component:#{component_type}"
        logger.fatal err
        throw err

      if info.default
        unless _.isArray info.default
          info.default = [info.default]

  # @param callback(err, account)
  triggerBilling: (account, callback) ->
    unless account.inPlan @name
      return callback null, callback

    if @billing_trigger.time
      @triggerTimeBilling account, (err, account) =>
        return callback err if err
        app.billing.checkArrearsAt account, callback
    else
      callback null, callback

  # @param callback(err, callback)
  acceptUsagesBilling: (account, trigger_name, volume, callback) ->
    {bucket, price, prepaid} = @billing_trigger[trigger_name]
    balance = account.plans[@name].billing_state[trigger_name]?.balance
    balance ?= 0

    if prepaid
      billing_bucket = Math.ceil (balance - volume) / -bucket
    else
      billing_bucket = Math.floor (balance - volume) / -bucket

    modifier =
      $inc: {}

    amount = billing_bucket * price
    balance_inc = -volume + billing_bucket * bucket
    modifier.$inc["plans.#{@name}.billing_state.balance"] = balance_inc

    if billing_bucket > 0
      modifier.$inc.balance = -amount

    Account.findByIdAndUpdate account._id, modifier, (err, account) =>
      unless billing_bucket > 0
        return callback err, account

      Financials.create
        account_id: account._id
        type: 'billing'
        amount: -amount
        payload:
          plan_name: @name
          billing_trigger: trigger_name
          billing_bucket_count: billing_bucket
          balance: balance + balance_inc
          amount_inc: -amount
      , (err) ->
        callback err, account

  # @param callback(err, account)
  triggerTimeBilling: (account, callback) ->
    {interval, price, prepaid} = @billing_trigger.time
    {expired_at} = account.plans[@name].billing_state.time

    if prepaid
      expect_paid = new Date Date.now() + interval
    else
      expect_paid = new Date()

    unless expired_at < expect_paid
      return callback null, account

    billing_time_range = expect_paid.getTime() - expired_at.getTime()
    billing_unit_count = Math.floor billing_time_range / interval

    unless billing_unit_count > 0
      return callback null, account

    new_expired_at = new Date expired_at.getTime() + billing_unit_count * interval
    amount = billing_unit_count * price

    modifier =
      $set: {}
      $inc:
        balance: -amount

    modifier.$set["plans.#{@name}.billing_state.time.expired_at"] = new_expired_at

    Account.findByIdAndUpdate account._id, modifier, (err, account) =>
      Financials.create
        account_id: account._id
        type: 'billing'
        amount: -amount
        payload:
          plan_name: @name
          billing_trigger: 'time'
          billing_unit_count: billing_unit_count
          expired_at: new_expired_at
          amount_inc: -amount
      , (err) ->
        callback err, account
