{pluggable, utils, config} = app
{_, async, mongoose, mongooseUniqueValidator} = app.libs

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

  account = new app.models.Account
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

Account.methods.matchPassword = (password) ->
  return @password == utils.hashPassword(password, @password_salt)

Account.methods.updatePassword = (password, callback) ->
  @password_salt = utils.randomSalt()
  @password = utils.hashPassword password, @password_salt
  @save callback

Account.methods.inGroup = (group) ->
  return group in @groups

_.extend app.models,
  Account: mongoose.model 'Account', Account

exports.incBalance = (account, type, amount, payload, callback) ->
  exports.update {_id: account._id},
    $inc:
      'billing.balance': amount
  , ->
    mBalance.create account, type, amount, payload, (err, balance_log) ->
      callback balance_log
