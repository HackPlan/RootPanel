_ = require 'lodash'
Q = require 'q'

###
  Class: Billing Plan, Managed by {BillingManager}.
###
class BillingPlan
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

  ###
    Public: Check has specified member.

    * `account` {Account}

    Return {Boolean}.
  ###
  hasMember: (account) ->
    return @name in _.keys account.plans

  ###
    Public: Add a member to plan.

    * `account` {Account}

    Return {Promise}.
  ###
  addMember: (account) ->
    @state(account).updatePlan
      $set:
        billing_state: {}
    .then =>
      @setupDefaultComponents()

  ###
    Public: Remove a member from plan.

    * `account` {Account}

    Return {Promise}.
  ###
  removeMember: (account) ->
    @state(account).removePlan().then =>
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

  ###
    Public: Get state wrapper object.

    * `account` {Account}

    Return {Object} with following method:

    * `plan` {Function} `-> Object`, Get plan state.
    * `updatePlan` {Function} `(updates) -> Promise`, Update plan state.
    * `removePlan` {Function} `-> Promise`, Remove plan state.
    * `trigger` {Function} `(trigger) -> Object`, Get trigger state.
    * `updateTrigger` {Function} `(trigger, updates) -> Promise`, Update trigger state.

  ###
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

###
  Manager: Billing manager,
  You can access a global instance via `root.billing`.
###
module.exports = class BillingManager
  constructor: (plans) ->
    @plans = {}

    for name, options of plans
      @plans[name] = new BillingPlan _.extend options,
        manager: @
        name: name

  ###
    Public: Get all billing plans.

    Return {Array} of {BillingPlan}.
  ###
  all: ->
    return _.values @plans

  ###
    Public: Get specified plan.

    Return {BillingPlan}.
  ###
  byName: (name) ->
    return @plans[name]

  ###
    Public: Trigger billing for specified account.

    * `account` {Account}

    Return {Promise}.
  ###
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

  ###
    Public: Invoke a usages billing.

    * `account` {Account}
    * `trigger` {String} e.g. `storage`, `cpu`
    * `volume` {Number}

    TODO: Should select the cheapest plan only.

    Return {Promise}.
  ###
  usagesBilling: (account, trigger, volume) ->
    Q.all @all().map (plan) ->
      if plan.hasMember(account) and plan.billing[trigger]
        plan.usagesBilling account, trigger, volume

  ###
    Public: Run time billing for all accounts.

    Return {Promise}.
  ###
  runTimeBilling: ->
    plans = @all().filter (plan) ->
      return plan.billing.time

    Account.findByPlans(_.pluck plans, 'name').then (accounts) =>
      Q.all accounts.map (account) =>
        @triggerBilling account

  ###
    Public: Destroy all overflowed components for specified account.

    * `account` {Account}

    Return {Promise}.
  ###
  destroyOverflowedComponents: (account) ->
    Component.getComponents(account).then (components) =>
      Q.all components.map (component) =>
        unless component.type in @availableComponents(account)
          component.destroy()

  ###
    Public: Remove specified account from all plans.

    * `account` {Account}

    Return {Promise}.
  ###
  leaveAllPlans: (account) ->
    Q.all _.keys(account.plans).map (name) =>
      @byName(name).removeMember account

  ###
    Public: Get current available component names of specified account.

    * `account` {Account}

    Return {Array} of {String}.
  ###
  availableComponents: (account) ->
    return _.uniq _.flatten _.keys(account.plans).map (name) =>
      return _.keys @byName(name).components

  ###
    Public: Check if account should be frozen.

    * `account` {Account}

    Return {Boolean}.
  ###
  isFrozen: ({balance, arrears_at}) ->
    {balance_below, arrears_above} = config.billing.freeze_conditions

    if balance < balance_below
      return true
    else if arrears_at and Date.now() > arrears_at.getTime() + arrears_above
      return true
    else
      return false
