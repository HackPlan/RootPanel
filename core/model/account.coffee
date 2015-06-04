validator = require 'validator'
Mabolo = require 'mabolo'
_ = require 'lodash'

utils = require '../utils'

###
  Model: Account Session Token Model,
  Embedded as a array at `tokens` of {Account}.
###
Token = Mabolo.model 'Token',
  # Public: Type of token
  type:
    required: true
    type: String
    enum: ['full_access', 'reset_password']

  # Public: Code of token, a sha256 string
  code:
    required: true
    type: String

  # Public: Custom options of token, e.g. `ip` and `ua`
  options:
    type: Object
    default: -> {}

  created_at:
    required: true
    type: Date
    default: -> new Date()

  updated_at:
    required: true
    type: Date
    default: -> new Date()

###
  Model: Account Preferences Model,
  Embedded at `preferences` of {Account}.

  TODO: verify fields
###
Preferences = Mabolo.model 'Preferences',
  # Public: A url refer to a avatar of account
  avatar_url: String
  # Public: A language code, e.g. `zh-CN`
  language: String
  # Public: A timezone code, e.g. `Asia/Shanghai`
  timezone: String
  # Public: QQ account number
  qq: String

###
  Model: Account Model.
###
module.exports = Account = Mabolo.model 'Account',
  # Public: User name
  username:
    required: true
    type: String
    validator: (username) ->
      unless validator.isUsername username
        throw new Error 'invalid_username'

  # Public: Email address
  email:
    required: true
    type: String
    validator: (email) ->
      unless validator.isEmail email
        throw new Error 'invalid email'

  # Public: Password
  password:
    type: String

  # Public: Salt of password
  password_salt:
    type: String

  # Public: Preferences
  preferences: Preferences

  # Public: Joined groups
  groups: [String]

  # Public: Available {Token}s
  tokens: [Token]

  # Public: Joined plans and it's states
  plans:
    type: Object
    default: -> {}

  # Public: Current balance
  balance:
    type: Number
    default: 0

  # Public: Last arrears time
  arrears_at:
    type: Date

  created_at:
    required: true
    type: Date
    default: -> new Date()

Account.ensureIndex
  username: 1
,
  unique: true

Account.ensureIndex
  email: 1
,
  unique: true

Account.ensureIndex
  'tokens.code': 1
,
  sparse: true
  unique: true

###
  Public: Revoke this token.

  Return {Promise}.
###
Token::revoke = ->
  @parent().update
    $pull:
      tokens:
        code: @code

###
  Section: Find account
###

###
  Public: Search account by `username`, `email` or `_id`.

  * `identify` {String} or {ObjectID}

  Return {Promise} resolve with {Account} or null.
###
Account.search = (identify) ->
  @findOne(username: identify).then (account) =>
    if account
      return account

    @findOne(email: identify).then (account) =>
      if account
        return account

      @findById(identify).catch ->
        return null

###
  Public: Authenticate with code of token.

  * `tokenCode` {String}

  This function will update `updated_at` of {Token}.

  Return {Promise} resolve with `{account: Account, token: Token}` or `{}`.
###
Account.authenticate = (tokenCode) ->
  @findOneAndUpdate
    'tokens.code': tokenCode
  ,
    $set:
      'tokens.$.updated_at': new Date()

  .then (account) ->
    return {
      account: account

      token: _.findWhere account?.tokens,
        code: tokenCode
    }

###
  Extended: Find accounts by group.

  * `group` {String}
  * more options passed to {Model.find}

  Return {Promise} resolve with array of {Account}.
###
Account.findByGroup = (group, options...) ->
  @find groups: group, options...

###
  Extended: Find accounts by plans.

  * `plans` {Array} of {String}
  * more options passed to {Model.find}

  Return {Promise} resolve with array of {Account}.
###
Account.findByPlans = (plans, options...) ->
  query = {}

  for plan in plans
    query["plans.#{plan}"] =
      $exists: true

  @find query, options...

###
  Section: Create account and token
###

###
  Public: Create a new {Account}.

  * `account` {Object}

    * `username` {String}
    * `email` {String}
    * `password` {String} Plain password

  This function will execute `account.before_register` hooks.

  Return {Promise} resolve with created {Account}.
###
Account.register = ({username, email, password}) ->
  password_salt = utils.randomSalt()
  password = utils.hashPassword password, password_salt

  avatar_url = '//cdn.v2ex.com/gravatar/' + utils.md5(email)

  account = new Account
    email: email?.toLowerCase()
    username: username
    password: password
    password_salt: password_salt

    preferences:
      avatar_url: avatar_url

  root.hooks.executeHooks('account.before_register',
    execute: 'filter'
    params: [account]
  ).then ->
    account.save()

###
  Public: Create token for this account.

  * `type` {String} Type of {Token}
  * `options` (optional) {Object} Options of {Token}

  Return {Promise} resolve with create {Token}.
###
Account::createToken = (type, options) ->
  token = new Token
    type: type
    code: utils.randomSalt()
    options: options
    created_at: new Date()
    updated_at: new Date()

  @update
    $push:
      tokens: token
  .thenResolve token

###
  Public: Remove all token and create a new one just for reset password.

  * `options` {Object} Options of {Token}

  Return {Promise} resolve with the new token.
###
Account::forgetPassword = (options) ->
  token = new Token
    type: 'reset_password'
    code: utils.randomSalt()
    options: options
    created_at: new Date()
    updated_at: new Date()

  @update
    $set:
      tokens: [token]
  .thenResolve token

###
  Section: Interaction with account instance
###

###
  Public: Pick account fields for specified role.

  * `role` {String} `admin`, `self` or `other`.

  Return {Object}.
###
Account::pick = (role) ->
  account = _.omit @, 'password', 'password_salt', 'tokens'

  switch role
    when 'admin'
      return account

    when 'self'
      return account

    else
      return {
        username: @username
        groups: @group
        preferences:
          avatar_url: @preferences.avatar_url
      }

###
  Public: Increase current balance.

  * `amount` {Number} e.g. `10` or `-5`

  Return {Promise}.
###
Account::increaseBalance = (amount) ->
  @update
    $inc:
      balance: amount

###
  Public: Check the password.

  * `password` {String} Plain password.

  Return {Boolean}.
###
Account::matchPassword = (password) ->
  return @password == utils.hashPassword(password, @password_salt)

###
  Public: Set password.

  * `password` {String} New plain password.

  Return {Promise}.
###
Account::setPassword = (password) ->
  password_salt = utils.randomSalt()
  password = utils.hashPassword password, password_salt

  @update
    $set:
      password: password
      password_salt: password_salt

###
  Public: Update preferences.

  * `preferences` {Preferences}

  Return {Promise}.
###
Account::updatePreferences = (preferences) ->
  preferences = new Preferences preferences

  preferences.validate().then =>
    modifier =
      $set: {}

    for name, value of preferences.toObject()
      modifier.$set["preferences.#{name}"] = value

    @update modifier

###
  Extended: Check admin role.

  Return {Boolean}.
###
Account::isAdmin = ->
  return @inGroup 'root'

###
  Extended: Check in specified group.

  * `group` {String}

  Return {Boolean}.
###
Account::inGroup = (group) ->
  return group in @groups

Account::joinGroup = (group) ->
  @update
    $addToSet:
      groups: group

###
  Public: Set email.

  * `email` {String}

  Return {Promise}.
###
Account::setEmail = (email) ->
  @update
    $set:
      email: email
