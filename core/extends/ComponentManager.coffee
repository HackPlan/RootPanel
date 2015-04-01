{config, logger} = app
{_} = app.libs

class ComponentProvider
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

  initialize: (component) ->
    Q()

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

module.exports = class ComponentManager
  constructor: ->
    @providers = {}

  register: (plugin, options) ->
    unless plugin
      throw new Error 'must provide a plugin'

    name = "#{plugin.name}.#{options.name}"

    if @providers[name]
      throw new Error "component `#{name}` already exists"

    @providers[name] = new ComponentProvider _.extend options,
      name: name
      plugin: plugin

  all: ->
    return _.values @plugins

  byName: (name) ->
    return @plugins[name]
