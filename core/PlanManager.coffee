_ = require 'lodash'
Q = require 'q'

class Plan
  defaults:
    name: null
    join_freely: true
    components: {}
    billing: {}

  constructor: (options) ->
    _.extend @, @defaults, options

    for type, {defaults} of @components
      if _.isArray defaults
        defaults = defaults
      else if _.isFunction defaults
        defaults = [defaults]
      else
        defaults = []

      _.extend @components[type],
        type: type
        defaults: defaults

  hasMember: (account) ->
    return @name in _.keys account.plans

  addMember: (account) ->
    @updatePlanState(account,
      $set:
        billing_state: {}
    ).then =>
      @setupDefaultComponents()

  removeMember: (account) ->
    removePlanState(account).then =>
      @manager.destroyOverflowedComponents account

  setupDefaultComponents: (account) ->
    Q.all _.values(@components).map ({type, defaults}) ->
      Q.all defaults.map (defaultOptions) ->
        rp.components.byName(type).createComponent account, defaultOptions(account)

  triggerTimeBilling: (account) ->
    unless @billing.time
      return Q()

    {interval, price, prepaid} = @billing.time
    state = @state account
    paid_to = state.trigger('time').paid_to ? new Date()

    if prepaid
      expired_at = new Date Date.now() + interval
    else
      expired_at = new Date()

    units = Math.floor (expired_at - paid_to) / interval
    latest_paid_to = new Date expired_at.getTime() + units * interval
    paid_amount = units * price

    if expired_at > paid_to and units > 0
      Account.increaseBalance(-paid_amount).then ->
        state.updateTrigger account, 'time',
          $set:
            paid_to: latest_paid_to
      .then =>
        Financials.createLog account, 'billing', payed_amount,
          plan: @name
          trigger: 'time'
          units: units
          paid_to: latest_paid_to
          paid_amount: paid_amount

    else
      return Q()

  usagesBilling: (account, trigger, volume) ->
    {bucket, price, prepaid} = @billing[trigger]
    state = @state account
    current = state.trigger(trigger).current ? 0

    if prepaid
      buckets = Math.ceil (current - volume) / -bucket
    else
      buckets = Math.floor (current - volume) / -bucket

    paid_amount = buckets * price
    current_inc = -volume + buckets * bucket
    latest_current = current + current_inc

    if buckets > 0
      Account.increaseBalance(-paid_amount).then ->
        state.updateTrigger account, trigger,
          $inc:
            current: current_inc
      .then =>
        Financials.createLog account, 'billing', payed_amount,
          plan: @name
          trigger: trigger
          units: buckets
          current: latest_current
          paid_amount: paid_amount

    else
      return Q()

  state: (account) ->
    {name} = @

    return {
      plan: ->
        return account.plans[name] ? {}

      updatePlan: (updates) ->
        modifier = {}

        for operator, commands of updates
          for path, value of commands
            modifier[operator] ?= {}
            modifier[operator]["plans.#{name}.#{path}"] = value

        account.update modifier

      removePlan: ->
        modifier =
          $unset: {}

        modifier.$unset["plans.#{name}"] = true

        account.update modifier

      trigger: (trigger) ->
        return @plan()[trigger] ? {}

      updateTrigger: (trigger, updates) ->
        modifier = {}

        for operator, commands of updates
          for path, value of commands
            modifier[operator] ?= {}
            modifier[operator]["billing.#{trigger}.#{path}"] = value

        @updatePlan modifier
    }

module.exports = class PlanManager
  constructor: (plans) ->
    @plans = {}

    for name, options of plans
      @plans[name] = new Plan _.extend options,
        manager: @
        name: name

  all: ->
    return _.values @plans

  byName: (name) ->
    return @plans[name]

  triggerBilling: (account) ->
    Q.all @all().map (plan) ->
      if plan.billing.time
        plan.triggerTimeBilling account
    .then ->
      if account.balance < 0 and !account.arrears_at
        account.update
          $set:
            arrears_at: new Date()
      else if account.balance > 0 and account.arrears_at
        account.update
          $set:
            arrears_at: null
    .then =>
      if @isFrozen account
        @leaveAllPlans account

  usagesBilling: (account, trigger, volume) ->
    Q.all @all().map (plan) ->
      if plan.hasMember(account) and plan.billing[trigger]
        plan.usagesBilling account, trigger, volume

  runTimeBilling: ->
    plans = @all().filter (plan) ->
      return plan.billing.time

    Account.findByPlans(_.pluck plans, 'name').then (accounts) =>
      Q.all accounts.map (account) =>
        @triggerBilling account

  destroyOverflowedComponents: (account) ->
    Component.getComponents(account).then (components) =>
      Q.all components.map (component) =>
        unless component.type in @availableComponents(account)
          component.destroy()

  leaveAllPlans: (account) ->
    Q.all _.keys(account.plans).map (name) =>
      @byName(name).removeMember account

  availableComponents: (account) ->
    return _.uniq _.flatten _.keys(account.plans).map (name) =>
      return _.keys @byName(name).components

  isFrozen: ({balance, arrears_at}) ->
    {balance_below, arrears_above} = config.billing.freeze_conditions

    if balance < balance_below
      return true
    else if arrears_at and Date.now() > arrears_at.getTime() + arrears_above
      return true
    else
      return false
