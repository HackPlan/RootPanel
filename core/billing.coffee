class Plan
  join_freely: true

  constructor: (options) ->
    _.extend @, options

    @available_components = {}

    if options.available_components
      for component_type, info of options.available_components
        if info.default
          unless _.isArray info.default
            info.default = [info.default]

        unless component_type.match /\./
          component_type = "#{component_type}.#{component_type}"

        @available_components[component_type] = info

  # @param callback(err, account)
  triggerBilling: (account, callback) ->
    unless account.inPlan @name
      return callback null, callback

    if @billing_trigger.time
      @triggerTimeBilling account, (err, account) ->
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

billing.triggerBilling = (account, callback) ->
  async.each account.plans, (plan, callback) ->
    app.plans[plan].triggerBilling account, callback
  , (err) ->
    return callback err if err

    if billing.isForceFreeze account
      account.leaveAllPlans callback
    else
      callback err, account

billing.acceptUsagesBilling = (account, trigger_name, volume, callback) ->
  plan_names = _.filter app.plans, (plan) ->
    return plan.billing_trigger[trigger_name] and account.inPlan plan

  async.each plan_names, (plan_name, callback) ->
    app.plans[plan_name].acceptUsagesBilling account, trigger_name, volume, callback
  , callback

billing.runTimeBilling = (callback = -> ) ->
  plan_names = _.filter app.plans, (plan) ->
    return plan.billing_trigger.time

  Account.find
    'plans':
      $in: plan_names
  , (err, accounts) ->
    async.each accounts, (account, callback) ->
      billing.triggerBilling account, callback
    , callback

# @param callback(err, account)
billing.checkArrearsAt = (account, callback) ->
  if account.balance < 0 and !account.arrears_at
    Account.findByIdAndUpdate account._id,
      $set:
        arrears_at: new Date()
    , callback
  else if account.balance > 0 and account.arrears_at
    Account.findByIdAndUpdate account._id,
      $set:
        arrears_at: null
    , callback
  else
    callback null, callback

billing.isForceFreeze = (account) ->
  {force_freeze} = config.billing

  if _.isEmpty account.plans
    return false

  if account.balance < force_freeze.when_balance_below
    return true

  if account.arrears_at
    if Date.now() > account.arrears_at.getTime() + force_freeze.when_arrears_above
      return true

  return false

billing.joinPlan = (account, plan_name, callback) ->
  plan = app.plans[plan_name]

  modifier =
    $set: {}

  modifier.$set["plans.#{plan.name}"] =
    billing_state:
      time:
        expired_at: new Date()

  plan.triggerBilling account, ->
    Account.findByIdAndUpdate account._id, modifier, (err, account) ->
      async.each _.keys(plan.available_components), (component_type, callback) ->
        plan_component_info = plan.available_components[component_type]
        component_type = pluggable.components[component_type]

        unless plan_component_info.default
          return callback()

        async.each plan_component_info.default, (defaultInfo, callback) ->
          default_info = defaultInfo account

          component_type.createComponent account,
            node_name: default_info.node_name ? 'master'
            name: default_info.name ? ''
            payload: default_info
          , callback

        , callback

      , callback

billing.leavePlan = (account, plan_name, callback) ->
  plan = app.plans[plan_name]

  modifier =
    $unset: {}

  modifier.$unset["plans.#{plan.name}"] = true

  plan.triggerBilling account, ->
    Account.findByIdAndUpdate account._id, modifier, (err, account) ->
      available_component_types = account.getAvailableComponentsTemplates()

      Component.getComponents account, (err, components) ->
        async.each components, (component, callback) ->
          if component.template in available_component_types
            return callback()

          template = pluggable.components[component.template]
          template.destroyComponent component, callback

        , callback

billing.leaveAllPlans = (account, callback) ->
  async.each account.plans, (plan_name, callback) ->
    billing.leavePlan account, plan_name, callback
  , (err) ->
    return callback err if err
    Account.findById account._id, callback
