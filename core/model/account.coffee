{pluggable} = app
{selectModelEnum} = pluggable
{_, async, mongoose} = app.libs

Token = mongoose.Schema
  type:
    required: true
    type: String
    enum: ['full_access']

  token:
    required: true
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
    type: String

  email:
    required: true
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

# @param account: username, email, password
# @param callback(account)
Account.statics.register = (account, callback) ->
  password_salt = utils.randomSalt()

  {username, email, password} = account

  account = new Account
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
    account.save ->
      callback account

_.extend app.models,
  Account: mongoose.model 'Account', Account

exports.updatePassword = (account, password, callback) ->
  password_salt = utils.randomSalt()

  exports.update {_id: account._id},
    $set:
      password: utils.hashPassword password, password_salt
      password_salt: password_salt
  , callback

exports.search = (username, callback) ->
  exports.findOne
    username: username
  , (err, account) ->
    if account
      return callback null, account

    exports.findOne
      email: username
    , (err, account) ->
      if account
        return callback null, account

      exports.findOne
        _id: new ObjectID username
      , (err, account) ->
        callback null, account

exports.matchPassword = (account, password) ->
  return utils.hashPassword(password, account.password_salt) == account.password

exports.incBalance = (account, type, amount, payload, callback) ->
  exports.update {_id: account._id},
    $inc:
      'billing.balance': amount
  , ->
    mBalance.create account, type, amount, payload, (err, balance_log) ->
      callback balance_log

exports.inGroup = (account, group) ->
  return group in account.groups
