_ = require 'underscore'
crypto = require 'crypto'

auth = require '../auth'
db = require '../db'
billing = require '../billing'

cAccount = db.collection 'accounts'

db.buildModel module.exports, cAccount

exports.byUsername = db.buildByXXOO 'username', cAccount
exports.byEmail = db.buildByXXOO 'email', cAccount

sample =
  username: 'jysperm'
  passwd: '53673f434686ce045477f066f30eded55a9bb535a6cec7b73a60972ccafddb2a'
  passwd_salt: '53673f434686b535a6cec7b73a60ce045477f066f30eded55a9b972ccafddb2a'
  email: 'jysperm@gmail.com'
  signup_at: Date()

  group: ['root']

  setting:
    avatar_url: 'http://ruby-china.org/avatar/efcc15b92617a95a09f514a9bff9e6c3?s=58'
    language: 'zh_CN'
    QQ: '184300584'

  attribute:
    service: ['shadowsocks']
    plans: ['all']

    balance: 100
    last_billing_at: Date()
    arrears_at: Date()

    resources_limit:
      cpu: 144
      storage: 520
      transfer: 39
      memory: 27

  tokens: [
    token: 'b535a6cec7b73a60c53673f434686e04972ccafddb2a5477f066f30eded55a9b'
    available: true
    created_at: Date()
    updated_at: Date()
    attribute:
      ip: '123.184.237.163'
      ua: 'Mozilla/5.0 (Intel Mac OS X) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.102'
  ]

exports.register = (username, email, passwd, callback = null) ->
  passwd_salt = auth.randomSalt()

  exports.insert
    _id: db.ObjectID()
    username: username
    passwd: auth.hashPasswd(passwd, passwd_salt)
    passwd_salt: passwd_salt
    email: email
    signup_at: new Date()
    group: []
    setting:
      avatar_url: "//ruby-china.org/avatar/#{crypto.createHash('md5').update(email).digest('hex')}?s=58"
    attribute:
      service: []
      plans: []
      balance: 0
      last_billing_at: new Date()
      arrears_at: null
      resources_limit: []
    tokens: []
  , {}, callback

exports.updatePasswd = (account, passwd, callback) ->
  passwd_salt = auth.randomSalt()

  exports.update _id: account._id,
    $set:
      passwd: auth.hashPasswd(passwd, passwd_salt)
      passwd_salt: passwd_salt
  , {}, callback

# @param callback(token)
exports.createToken = (account, attribute, callback) ->
  # @param callback(token)
  generateToken = (callback) ->
    token = auth.randomSalt()

    exports.findOne
      'tokens.token': token
    , {}, (result) ->
      if result
        generateToken callback
      else
        callback token

  generateToken (token) ->
    exports.update _id: account._id,
      $push:
        tokens:
          token: token
          available: true
          created_at: new Date()
          updated_at: new Date()
          attribute: attribute
    , {}, ->
      callback token

exports.removeToken = (token, callback) ->
  exports.update 'tokens.token': token,
    $pull:
      tokens:
        token: token
  , {}, callback

exports.authenticate = (token, callback) ->
  unless token
    return callback null

  exports.findOne
    'tokens.token': token
  , {}, callback

exports.byUsernameOrEmailOrId = (username, callback) ->
  exports.byUsername username, (account) ->
    if account
      return callback account

    exports.byEmail username, (account) ->
      if account
        return callback account

      exports.findId username, callback

# @return bool
exports.matchPasswd = (account, passwd) ->
  return auth.hashPasswd(passwd, account.passwd_salt) == account.passwd

exports.inGroup = (account, group) ->
  return group in account.group

exports.joinPlan = (account, plan, callback) ->
  account.attribute.plans.push plan
  exports.update _id: account._id,
    $addToSet:
      'attribute.plans': plan
    $set:
      'attribute.resources_limit': billing.calcResourcesLimit account.attribute.plans
  , {}, callback

exports.leavePlan = (account, plan, callback) ->
  account.attribute.plans = _.reject account.attribute.plans, (i) -> i == plan
  exports.update _id: account._id,
    $pull:
      'attribute.plans': plan
    $set:
      'attribute.resources_limit': billing.calcResourcesLimit account.attribute.plans
  , {}, callback

exports.incBalance = (account, amount, callback) ->
  exports.update _id: account._id,
    $inc:
      'attribute.balance': amount
  , {}, callback
