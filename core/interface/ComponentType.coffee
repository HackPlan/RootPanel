{_, async} = app.libs
{logger} = app
{Account, Component} = app.models

Node = require './Node'

module.exports = class ComponentType
  @component_types = {}

  @get: (name) ->
    return @component_types[name]

  constructor: (info) ->
    _.extend @, info

  pickPayload: (info) ->
    return info

  # @param callback(err)
  initialize: (component, callback) ->
    callback()

  # @param callback(err, component)
  createComponent: (account, info, callback) ->
    {name, physical_node} = info

    Component.create
      account_id: account._id
      component_type: @name
      payload: @pickPayload info
      name: name
      physical_node: physical_node
      dependencies: {}
    , (err, component) =>
      component.populateComponent (populated_component) =>
        @initialize populated_component, (err) =>
          return callback err if err

          component.markAsStatus 'running', callback

  # @param callback(err)
  destroyComponent: (component, callback) ->
    component.markAsStatus 'destroying', (err) =>
      return callback err if err

      component.populateComponent (component) =>
        @destroy component, (err) =>
          return callback err if err

          Component.findByIdAndRemove component._id, callback

  setCoworkers: (component, updates, callback) ->

  transferOwner: ->

  movePhysicalNode: ->

  packing: ->

  unpacking: ->
