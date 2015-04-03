{mabolo} = app
{ObjectID} = mabolo

_ = require 'underscore'
Q = require 'q'

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

  type:
    required: true
    type: String

  node:
    required: true
    type: String

  status:
    type: String
    enum: ['running', 'initializing', 'destroying']
    default: 'initializing'

  options:
    type: Object

  dependencies:
    type: Object

  coworkers: [Coworker]

Component.getComponents = (account) ->
  @find
    $or: [
      account_id: account._id
    ,
      'coworkers.account_id': account._id
    ]

Component::hasMember = (account) ->
  if @account_id.equals account._id
    return true

  return _.some @coworkers, (coworker) ->
    return coworker.account_id.equals account._id

Component::setStatus = (status) ->
  @update
    $set:
      status: status

Component::destroy = ->
  @populate().then =>
    @provider.destroyComponent @

Component::populate = ->
  Account.find
    _id:
      $in: [
        @account_id, _.pluck(@coworkers, 'account_id')...
      ]

  .then (accounts) =>
    @account = _.find accounts, ({_id}) =>
      return @account_id.equals _id

    for coworker in @coworkers
      coworker.account = _.find accounts, ({_id}) ->
        return coworker.account_id.equals _id

    return _.extend @,
      provider: rp.components.byName @type
      node: rp.nodes.byName @node
