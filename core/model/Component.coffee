{_, ObjectId, mongoose, async} = app.libs
{Account} = app.models

Component = mongoose.Schema
  component_type:
    required: true
    type: String
    enum: []

  name:
    required: true
    type: String

  account_id:
    required: true
    type: ObjectId
    ref: 'Account'

  coworkers: [
    account_id:
      required: true
      type: ObjectId
      ref: 'Account'

    role:
      required: true
      type: String
      enum: ['readonly', 'readwrite']
  ]

  status:
    type: String
    enum: ['running', 'initializing', 'destroying']
    default: 'initializing'

  payload:
    type: Object

  dependencies:
    type: Object

  physical_node:
    required: true
    type: String
    enum: []

Component.methods.populateComponent = (callback) ->
  component = @toObject()

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
      component_type: ComponentType.get component.component_type
      physical_node: Node.get component.physical_node

Component.methods.markAsStatus = (status, callback) ->
  @status = status
  @save callback

_.extend app.models,
  Component: mongoose.model 'Component', Component
