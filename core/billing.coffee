{config, pluggable, logger} = app
{async, _} = app.libs
{Account, Financials, Component} = app.models

process.nextTick ->
  {Account, Component} = app.models

Plan = require './interface/Plan'
ComponentTemplate = require './interface/ComponentTemplate'

billing = _.extend exports,
  plans: {}

billing.initPlans = ->
  for name, info of config.plans
    billing.plans[name] = new Plan _.extend info,
      name: name

  app.on 'app.started', ->
    billing.runTimeBilling ->
      setInterval billing.runTimeBilling, 3600 * 1000

billing.triggerBilling = (account, callback) ->
  async.each account.plans, (plan, callback) ->
    billing.plans[plan].triggerBilling account, callback
  , (err) ->
    return callback err if err

    if billing.isForceFreeze account
      account.leaveAllPlans callback
    else
      callback err, account

billing.acceptUsagesBilling = (account, trigger_name, volume, callback) ->
  plan_names = _.filter billing.plans, (plan) ->
    return plan.billing_trigger[trigger_name] and account.inPlan plan

  async.each plan_names, (plan_name, callback) ->
    billing.plans[plan_name].acceptUsagesBilling account, trigger_name, volume, callback
  , callback

billing.runTimeBilling = (callback = ->) ->
  plan_names = _.filter billing.plans, (plan) ->
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
  plan = billing.plans[plan_name]

  modifier =
    $set: {}

  modifier.$set["plans.#{plan.name}"] =
    billing_state:
      time:
        expired_at: new Date()

  plan.triggerBilling account, =>
    Account.findByIdAndUpdate account._id, modifier, (err, account) ->
      async.each _.keys(plan.available_components), (component_type, callback) =>
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

      , (err) ->
        console.log 'async.each', arguments
        callback(err)

billing.leavePlan = (account, plan_name, callback) ->
  plan = billing.plans[plan_name]

  modifier =
    $unset: {}

  modifier.$unset["plans.#{plan.name}"] = true

  plan.triggerBilling account, =>
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
  async.each account.plans, (plan_name, callback) =>
    billing.leavePlan account, plan_name, callback
  , (err) =>
    return callback err if err
    Account.findById account._id, callback
