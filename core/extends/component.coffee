{config, logger} = app
{_} = app.libs

app.components ?= {}

class ComponentTemplate
  isComponent: true

  constructor: (info) ->
    _.extend @, info

  registerHook: (endpoint, options) ->
    app.extends.hook.register @, endpoint, options

  registerHookAlways: (endpoint, options) ->
    app.extends.hook.register @, endpoint, _.extend options,
      timing: 'always'

  registerHookAvailable: (endpoint, options) ->
    app.extends.hook.register @, endpoint, _.extend options,
      timing: 'available'

  registerHookOnce: (endpoint, options) ->
    app.extends.hook.register @, endpoint, _.extend options,
      timing: 'once'

  registerHookEvery: (endpoint, options) ->
    app.extends.hook.register @, endpoint, _.extend options,
      timing: 'every'

  registerHookEveryNode: (endpoint, options) ->
    app.extends.hook.register @, endpoint, _.extend options,
      timing: 'every_node'

  # @param callback(err)
  initialize: (component, callback) ->
    callback()

  # @param callback(err, component)
  createComponent: (account, info, callback) ->
    {name, node_name, payload} = info

    Component.create
      account_id: ObjectID account._id.toString()
      template: @name
      payload: payload
      name: name
      node_name: node_name
      dependencies: {}
    , (err, component) =>
      return callback err if err
      component.populate =>
        @initialize component, (err) ->
          return callback err if err

          component.markAsStatus 'running', callback

  # @param callback(err)
  destroyComponent: (component, callback) ->
    component.markAsStatus 'destroying', (err) =>
      return callback err if err

      component.populate =>
        @destroy component, (err) ->
          return callback err if err

          Component.findByIdAndRemove component._id, callback

  setCoworkers: (component, updates, callback) ->

  transferOwner: ->

  movePhysicalNode: ->

exports.register = (plugin, options) ->
  unless plugin
    throw error 'must provide a plugin'

  name = "#{plugin.name}.#{options.name}"

  if app.components[name]
    throw error "component `#{name}` already exists"

  app.components[name] = new ComponentTemplate _.extend options,
    name: name
    plugin: plugin

error = (message) ->
  err = new Error 'core.extends.component: ' + message
  logger.fatal err
  return err
