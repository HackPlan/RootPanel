{_} = app.libs
{config, logger} = app

{available_plugins} = config.plugin

module.exports = class Plan
  @plans = {}

  @initPlans: ->
    for name, info of config.plans
      @plans[name] = new Plan _.extend info,
        name: name

  @get: (name) ->
    return @plans[name]

  constructor: (info) ->
    _.extend @, info

    for component_type, info of @available_components
      unless component_type in available_plugins
        err = new Error "Plan:#{@name} include unknown Component:#{component_type}"
        logger.fatal err
        throw err

      if info.default
        unless _.isArray info.default
          info.default = [info.default]
