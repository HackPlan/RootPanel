{pluggable, utils, config, models} = app
{_, async, mongoose, mongooseUniqueValidator} = app.libs

Financial = null

process.nextTick ->
  {Financial} = app.models

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
    default: {}

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
    default: []

  tokens: [
    Token
  ]

  preferences:
    type: Object
    default: {}

  billing:
    services:
      type: Array
      default: []

    plans:
      type: Array
      default: []

    last_billing_at:
      type: Object
      default: {}

    balance:
      type: Number
      default: 0

    arrears_at:
      type: Date
      default: null

  pluggable:
    type: Object
    default: {}

  resources_limit:
    type: Object
    default: {}

Account.plugin mongooseUniqueValidator

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
      avatar_url: "//ruby-china.org/avatar/#{utils.md5(email)}?s=58"
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

_.extend app.models,
  Account: mongoose.model 'Account', Account
  Token: mongoose.model 'Token', Token
