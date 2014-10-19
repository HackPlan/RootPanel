async = require 'async'
_ = require 'underscore'

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

module.exports = mongoose.model 'Account', Account

# @param account: username, email, password
# @param callback(account)
exports.register = (account, callback) ->
  password_salt = utils.randomSalt()

  {username, email, password} = account

  account =
    username: username
    password: utils.hashPassword(password, password_salt)
    password_salt: password_salt
    email: email
    created_at: new Date()

    groups: []

    preferences:
      avatar_url: "//ruby-china.org/avatar/#{utils.md5(email)}?s=58"
      language: 'auto'
      timezone: config.i18n.default_timezone

    billing:
      services: []
      plans: []

      balance: 0
      last_billing_at: {}
      arrears_at: null

    pluggable: {}

    resources_limit: {}

    tokens: []

  async.each pluggable.selectHook(account, 'account.before_register'), (hook, callback) ->
    hook.filter account, callback
  , ->
    exports.insert account, (err, result) ->
      callback _.first result

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
