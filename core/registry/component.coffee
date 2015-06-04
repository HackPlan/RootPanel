_ = require 'lodash'

Component = require '../model/component'

###
  Class: Component provider, Managed by {ComponentRegistry}.
###
class ComponentProvider
  defaults:
    validate: (component) ->
    initialize: (component) ->
    update: (component) ->
    reconfigure: (component) ->
    destroy: (component) ->

  constructor: (options) ->
    _.extend @, @defaults, options

  ###
    Public: Create component.

    * `account` {Account}
    * `server` {ServerNode}
    * `component` {Object}

      * `name` {String}
      * `options` (optional) {Object}

    Return {Promise} resolve with created {Component}.
  ###
  create: (account, server, {name, options}) ->
    Component.createComponent account,
      type: @name
      options: options
      name: name
      node: server.name
      dependencies: {}
    .then (component) =>
      component.populate().then =>
        @initialize component
      .then ->
        component.setStatus 'running'

  ###
    Public: Destroy component.

    * `component` {Component}

    Return {Promise}.
  ###
  destroyComponent: (component) ->
    component.setStatus('destroying').then =>
      component.populate().then =>
        @destroy component
      .then ->
        component.remove()

  # TODO: Update coworkers.
  updateCoworkers: (component, updates) ->

###
  Registry: Component registry,
  You can access a global instance via `root.components`.
###
module.exports = class ComponentRegistry
  constructor: ->
    @providers = {}

  ###
    Public: Register a component provider.

    * `name` {String} e.g. `linux` or `vpn.pptp`.
    * `options` {Object}

      * `plugin` {Plugin}
      * `initialize` {Function} Received {Component}, return {Promise}.
      * `destroy` {Function} Received {Component}, return {Promise}.

    Return {ComponentProvider}.
  ###
  register: (name, options) ->
    unless '.' in name
      name = "#{options.plugin.name}.#{name}"

    if @providers[name]
      throw new Error "Component `#{name}` already exists"

    @providers[name] = new ComponentProvider _.extend options,
      name: name

  ###
    Public: Get all component providers.

    Return {Array} of {ComponentProvider}.
  ###
  all: ->
    return _.values @providers

  ###
    Public: Get specified provider.

    * `name` {String}

    Return {ComponentProvider}.
  ###
  byName: (name) ->
    return @providers[name]

ComponentRegistry.ComponentProvider = ComponentProvider
