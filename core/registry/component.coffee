_ = require 'lodash'

class ComponentProvider
  defaults:
    initialize: (component) ->
    destroy: (component) ->

  constructor: (options) ->
    _.extend @, options

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

  createComponent: (account, {name, node, options}) ->
    Component.create
      account_id: account._id
      type: @name
      options: options
      name: name
      node: node
      dependencies: {}
    .then (component) =>
      component.populate().then =>
        @initialize component
      .then ->
        component.setStatus 'running'

  destroyComponent: (component) ->
    component.setStatus('destroying').then =>
      component.populate().then =>
        @destroy component
      .then ->
        component.remove()

  setCoworkers: (component, updates) ->

  transferOwner: ->

  movePhysicalNode: ->

module.exports = class ComponentRegistry
  constructor: ->
    @providers = {}

  register: (options) ->
    name = "#{options.plugin.name}.#{options.name}"

    if @providers[name]
      throw new Error "component `#{name}` already exists"

    @providers[name] = new ComponentProvider _.extend options,
      name: name

  all: ->
    return _.values @providers

  byName: (name) ->
    return @providers[name]
