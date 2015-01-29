{_, async} = app.libs
{logger, mabolo} = app
{Account, Component} = app.models
{ObjectID} = mabolo

process.nextTick ->
  {Component} = app.models

Node = require './Node'

module.exports = class ComponentTemplate
  constructor: (info) ->
    _.extend @, info

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
        @initialize component, (err) =>
          return callback err if err

          component.markAsStatus 'running', callback

  # @param callback(err)
  destroyComponent: (component, callback) ->
    component.markAsStatus 'destroying', (err) =>
      return callback err if err

      component.populate =>
        @destroy component, (err) =>
          return callback err if err

          Component.findByIdAndRemove component._id, callback

  setCoworkers: (component, updates, callback) ->

  transferOwner: ->

  movePhysicalNode: ->
