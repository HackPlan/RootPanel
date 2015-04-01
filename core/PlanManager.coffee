_ = require 'underscore'
Q = require 'q'

class Plan
  defaults:
    name: null
    join_freely: true

  constructor: (options) ->
    _.extend @, @defaults, options

  addMember: (account) ->
    @updatePlanState(account,
      $set:
        billing_state: {}
    ).then =>
      @setupDefaultComponents()

  removeMember: (account) ->
    removePlanState(account).then ->
      app.plans.destroyOverflowedComponents account

  setupDefaultComponents: (account) ->
    return Q()

  updatePlanState: (account, updates) ->
    modifier = {}

    for operator, commands of updates
      for path, value of commands
        modifier[operator] ?= {}
        modifier[operator]["plans.#{@name}.#{path}"] = value

    account.update modifier

  removePlanState: (account) ->
    modifier =
      $unset: {}

    modifier.$unset["plans.#{@name}"] = true

    account.update modifier

module.exports = class PlanManager
  constructor: (plans_config) ->
    @plans = {}

    for name, options of plans_config
      @plans[name] = new Plan _.extend options,
        name: name

  all: ->
    return _.values @plans

  byName: (name) ->
    return @plans[name]

  destroyOverflowedComponents: (account) ->
    return Q()

  leaveAllPlans: (account) ->
    return Q()

  isFrozen: (account) ->
