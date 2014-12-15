module.exports = class Plan
  @plans = {}

  @initPlans: ->
    for name, info of config.plans
      @plans[name] = new @constructor _.extend info,
        name: name

  @get: (name) ->
    return @plans[name]

  constructor: (info) ->
    _.extend @, info

    for component_type, info of @available_components
      if info.default
        unless _.isArray info.default
          info.default = [info.default]
