{pluggable, utils, config, models, mabolo} = app
{_, async} = app.libs
{Financial, SecurityLog, Component} = app.models
{ObjectID} = mabolo

Plan = require '../interface/Plan'
billing = require '../billing'

process.nextTick ->
  {Financial, SecurityLog, Component} = app.models

Token = mabolo.model 'Token',
  type:
    required: true
    type: String

  token:
    required: true
    type: String

  payload:
    type: Object

  created_at:
    required: true
    type: Date
    default: -> new Date()

  updated_at:
    required: true
    type: Date
    default: -> new Date()

Token::revoke = (callback) ->
  @parent().update
    $pull:
      tokens:
        token: @token
  , callback

Account = mabolo.model 'Account',
  username:
    required: true
    type: String
    regex: utils.rx.username

  email:
    required: true
    type: String
    regex: utils.rx.email

  groups: [String]
  tokens: [Token]

  password:
    type: String

  password_salt:
    type: String

  preferences:
    type: Object

  plans:
    type: Object

  balance:
    type: Number
    default: 0

  arrears_at:
    type: Date

  pluggable:
    type: Object

  resources_limit:
    type: Object

  created_at:
    required: true
    type: Date
    default: -> new Date()

# @param account: username, email, password
# @param callback(err, account)
Account.register = (account, callback) ->
  password_salt = utils.randomSalt()

  {username, email, password} = account

  account = new @
    username: username
    email: email
    password: utils.hashPassword(password, password_salt)
    password_salt: password_salt

    preferences:
      avatar_url: "//cdn.v2ex.com/gravatar/#{utils.md5(email)}"
      language: 'auto'
      timezone: config.i18n.default_timezone

    pluggable: {}

  async.each pluggable.applyHooks('account.before_register'), (hook, callback) ->
    hook.filter account, callback
  , ->
    account.save (err) ->
      callback err, account

# @param callback(account)
Account.search = (stuff, callback) ->
  @findOne {username: stuff}, (err, account) =>
    if account
      return callback account

    @findOne {email: stuff}, (err, account) =>
      if account
        return callback account

      @findById stuff, (err, account) ->
        callback account

# @param callback(token)
Account.generateToken = (callback) ->
  token = utils.randomSalt()

  @findOne
    'tokens.token': token
  , (err, result) ->
    if result
      @generateToken callback
    else
      callback token

# @param callback(Token, Account)
Account.authenticate = (token, callback) ->
  unless token
    return callback()

  @findOneAndUpdate
    'tokens.token': token
  ,
    $set:
      'tokens.$.updated_at': new Date()
  , (err, account) ->
    matched_token = _.findWhere account?.tokens,
      token: token

    callback matched_token, account

# @param callback(err, Token)
Account::createToken = (type, payload, callback) ->
  models.Account.generateToken (token) =>
    token = new models.Token
      type: type
      token: token
      payload: payload

    token.validate (err) =>
      return callback err if err

      @tokens.push token

      @save (err) ->
        return callback err if err

        callback null, token

Account::matchPassword = (password) ->
  return @password == utils.hashPassword(password, @password_salt)

Account::updatePassword = (password, callback) ->
  @password_salt = utils.randomSalt()
  @password = utils.hashPassword password, @password_salt
  @save callback

# @param callback(err)
Account::incBalance = (amount, type, payload, callback) ->
  unless _.isNumber amount
    return callback 'invalid_amount'

  financials = new models.Financials
    account_id: @_id
    type: type
    amount: amount
    payload: payload

  financials.validate (err) =>
    return callback err if err

    @update
      $inc:
        balance: amount
    , (err) ->
      return callback err if err

      financials.save (err) ->
        callback err

Account::inGroup = (group) ->
  return group in @groups

Account::isAdmin = ->
  return @inGroup 'root'

Account::inPlan = (plan_name) ->
  return plan_name in _.keys @plans

Account::createSecurityLog = (type, token, payload, callback) ->
  SecurityLog.create
    account_id: @_id
    type: type
    token: _.pick token, 'type', 'token', 'created_at', 'payload'
    payload: payload
  , callback

Account::getAvailableComponentsTemplates = ->
  return _.uniq _.compact _.map _.keys(@plans), (plan_name) ->
    return _.keys billing.plans[plan_name].available_components

Account::populate = (callback) ->
  async.parallel
    components: (callback) =>
      Component.getComponents @, callback

  , (err, result) ->
    callback _.extend @, result
