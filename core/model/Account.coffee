{pluggable, utils, config, models} = app
{_, async, mongoose, mongooseUniqueValidator} = app.libs

{Financial, SecurityLog} = app.models

process.nextTick ->
  {Financial, SecurityLog} = app.models

Token = mongoose.Schema
  type:
    required: true
    type: String
    enum: ['full_access']

  token:
    required: true
    sparse: true
    unique: true
    type: String

  created_at:
    type: Date
    default: Date.now

  update_at:
    type: Date
    default: Date.now

  payload:
    type: Object

Token.methods.revoke = (callback) ->
  @ownerDocument().update
    $pull:
      tokens:
        token: @token
  , callback

_.extend app.models,
  Token: mongoose.model 'Token', Token

Account = mongoose.Schema
  username:
    required: true
    unique: true
    type: String

  email:
    lowercase: true
    required: true
    unique: true
    type: String

  password:
    type: String

  password_salt:
    type: String

  created_at:
    type: Date
    default: Date.now

  groups:
    type: Array

  tokens: [
    mongoose.modelSchemas.Token
  ]

  preferences:
    type: Object

  billing:
    services:
      type: Array

    plans:
      type: Array

    last_billing_at:
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

Account.plugin mongooseUniqueValidator,
  message: 'unique_validation_error'

Account.path('email').validate (email) ->
  return utils.rx.email.test email
, 'invalid_email'

Account.path('username').validate (username) ->
  return utils.rx.username.test username
, 'invalid_username'

Account.path('username').validate (username, callback) ->
  async.each pluggable.selectHook(null, 'account.username_filter'), (hook, callback) ->
    hook.filter username, (is_allow) ->
      if is_allow
        callback()
      else
        callback true

  , (not_allow) ->
    if not_allow
      callback()
    else
      callback true
, 'username_exist'

# @param account: username, email, password
# @param callback(err, account)
Account.statics.register = (account, callback) ->
  password_salt = utils.randomSalt()

  {username, email, password} = account

  account = new @
    username: username
    email: email
    password: utils.hashPassword(password, password_salt)
    password_salt: password_salt

    preferences:
      avatar_url: "//cdn.v2ex.com/gravatar/#{utils.md5(email)}?s=58"
      language: 'auto'
      timezone: config.i18n.default_timezone

  async.each pluggable.selectHook(account, 'account.before_register'), (hook, callback) ->
    hook.filter account, callback
  , ->
    account.save (err) ->
      callback err, account

# @param callback(account)
Account.statics.search = (stuff, callback) ->
  @findOne {username: stuff}, (err, account) =>
    if account
      return callback account

    @findOne {email: stuff}, (err, account) =>
      if account
        return callback account

      @findById stuff, (err, account) ->
        callback account

# @param callback(token)
Account.statics.generateToken = (callback) ->
  token = utils.randomSalt()

  @findOne
    'tokens.token': token
  , (err, result) ->
    if result
      @generateToken callback
    else
      callback token

# @param callback(Token, Account)
Account.statics.authenticate = (token, callback) ->
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
Account.methods.createToken = (type, payload, callback) ->
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

Account.methods.matchPassword = (password) ->
  return @password == utils.hashPassword(password, @password_salt)

Account.methods.updatePassword = (password, callback) ->
  @password_salt = utils.randomSalt()
  @password = utils.hashPassword password, @password_salt
  @save callback

# @param callback(err)
Account.methods.incBalance = (amount, type, payload, callback) ->
  unless _.isNumber amount
    return callback new Error 'amount must be a number'

  financials = new models.Financials
    account_id: @_id
    type: type
    amount: amount
    payload: payload

  financials.validate (err) =>
    return callback err if err

    @update
      $inc:
        'billing.balance': amount
    , (err) ->
      return callback err if err

      financials.save (err) ->
        callback err

Account.methods.inGroup = (group) ->
  return group in @groups

Account.methods.createSecurityLog = (type, token, payload, callback) ->
  SecurityLog.create
    account_id: @_id
    type: type
    token: _.pick token, 'type', 'token', 'created_at', 'payload'
    payload: payload
  , callback

_.extend app.models,
  Account: mongoose.model 'Account', Account
