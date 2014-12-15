{_, async} = app.libs
{logger} = app
{Node} = app.interfaces
{Account, Component} = app.models

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

  populateComponent: (component) ->
    if component.toObject
      component = component.toObject()

    async.parallel
      account: (callback) ->
        Account.findById component.account_id, callback

      coworkers: (callback) ->
        async.each component.coworkers, (coworker, callback) ->
          Account.findById coworker.account_id, (err, account) ->
            callback _.extend coworker,
              account: account
        , callback

    , (err, result) ->
      {account, coworkers} = result

      callback _.extend component,
        account: account
        coworkers: coworkers
        physical_node: Node.nodes[component.physical_node]

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
      @populateComponent component, (component) =>
        @initialize component, (err) =>
          return callback err if err

          Component.markAsStatus component, 'running', callback

  # @param callback(err)
  destroyComponent: (component, callback) ->
    Component.markAsStatus component, 'destroying', (err) =>
      return callback err if err

      @populateComponent component, (component) =>
        @destroy component, (err) =>
          return callback err if err

          Component.findByIdAndRemove component._id, callback

  setCoworkers: (component, updates, callback) ->

  transferOwner: ->

  movePhysicalNode: ->

  package: ->
