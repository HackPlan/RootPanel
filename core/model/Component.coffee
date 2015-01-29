{_, async} = app.libs
{mabolo, pluggable} = app
{ObjectID} = mabolo

Coworker = mabolo.model 'Coworker',
  account_id:
    required: true
    type: ObjectID
    ref: 'Account'

  role:
    required: true
    type: String
    enum: ['readonly', 'readwrite']

Component = mabolo.model 'Component',
  account_id:
    required: true
    type: ObjectID
    ref: 'Account'

  name:
    required: true
    type: String

  template:
    required: true
    type: String

  node_name:
    required: true
    type: String

  status:
    type: String
    enum: ['running', 'initializing', 'destroying']
    default: 'initializing'

  payload:
    type: Object

  dependencies:
    type: Object

  coworkers: [Coworker]

Component.getComponents = (account, callback) ->
  @find
    $or: [
      account_id: account._id
    ,
      'coworkers.account_id': account._id
    ]
  , (err, components) ->
    callback err, components

Component::hasMember = (account) ->
  if @account_id.equals account._id
    return true

  return _.some @coworkers, (coworker) ->
    return coworker.account_id.equals account._id

Component::markAsStatus = (status, callback) ->
  @update
    $set:
      status: status
  , callback

Component::populate = (callback) ->
  {Account} = app.models

  async.parallel
    account: (callback) =>
      Account.findById @account_id, callback

    coworkers: (callback) =>
      async.each @coworkers, (coworker, callback) ->
        Account.findById coworker.account_id, (err, account) ->
          callback _.extend coworker,
            account: account
      , callback

  , (err, result) =>
    {account, coworkers} = result

    callback _.extend @,
      account: account
      coworkers: coworkers
      component_type: pluggable.components[@template]
      node: app.nodes[@node_name]
