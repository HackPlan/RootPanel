Mabolo = require 'mabolo'
_ = require 'lodash'
Q = require 'q'

{ObjectID} = Mabolo

###
  Model: Component coworker,
  Embedded as a array at `coworkers` of {Component}.
###
Coworker = Mabolo.model 'Coworker',
  # Public: Related account
  account_id:
    required: true
    type: ObjectID
    ref: 'Account'

  # Public: Role of this account
  role:
    required: true
    type: String
    enum: ['readonly', 'readwrite']

###
  Model: Component.
###
module.exports = Component = Mabolo.model 'Component',
  # Public: Owner account
  account_id:
    required: true
    type: ObjectID
    ref: 'Account'

  # Public: Coworkers
  coworkers: [Coworker]

  # Public: Name of component, just for display
  name:
    required: true
    type: String

  # Public: {ComponentProvider} of component
  type:
    required: true
    type: String

  # Public: {ServerNode} of component
  node:
    required: true
    type: String

  # Public: Current status
  status:
    type: String
    enum: ['running', 'initializing', 'destroying']
    default: 'initializing'

  # Public: Custom options of component, used by provider
  options:
    type: Object
    default: -> {}

  # Public: Components that this component depend on
  dependencies:
    type: Object
    default: -> {}

Account = require './account'

Component.createComponent = (account, {name, type, node, dependencies, options}) ->
  @create
    account_id: account._id
    name: name
    type: type
    node: node
    options: options
    dependencies: dependencies

###
  Public: Find components belongs to account.

  * `account` {Account}

  Return {Promise} resolve with array of {Component}.
###
Component.getComponents = (account) ->
  @find
    $or: [
      account_id: account._id
    ,
      'coworkers.account_id': account._id
    ]

###
  Public: Set status.

  * `status` {String} New status.

  Return {Promise}.
###
Component::setStatus = (status) ->
  @update
    $set:
      status: status

###
  Public: Destroy and remove component.

  This function will call {Provider::destroyComponent}.

  Return {Promise}.
###
Component::destroy = ->
  @populate().then =>
    @provider.destroyComponent @

###
  Public: Check has specified member.

  * `account` {Account}

  Return {Boolean}.
###
Component::hasMember = (account) ->
  if @account_id.equals account._id
    return true

  return @coworkers.some ({account_id}) ->
    return account_id.equals account._id

###
  Public: Populate refs accounts.

  This function will populate following fields:

  * `account`: {Account} from `account_id`.
  * `coworker.$.account`: {Account} from `coworker.$.account_id`.
  * `provider`: {ComponentProvider} from `type`.
  * `server`: {ServerNode} from `node`.

  Return {Promise}.
###
Component::populate = ->
  if @account and @provider and @server
    return Q @

  Account.find
    _id:
      $in: [
        @account_id, _.pluck(@coworkers, 'account_id')...
      ]

  .then (accounts) =>
    @account = _.find accounts, ({_id}) =>
      return @account_id.equals _id

    @coworkers.forEach (coworker) ->
      coworker.account = _.find accounts, ({_id}) ->
        return coworker.account_id.equals _id

    return _.extend @,
      provider: root.components.byName @type
      server: root.servers.byName @node
