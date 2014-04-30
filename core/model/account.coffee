_ = require 'underscore'
crypto = require 'crypto'

auth = require '../auth'
db = require '../db'

cAccount = db.collection 'accounts'

db.buildModel module.exports, cAccount

exports.byUsername = db.buildByXXOO 'username', cAccount
exports.byEmail = db.buildByXXOO 'email', cAccount

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
    attribure:
      plans: []
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
  exports.update
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

exports.byUsernameOrEmail = (username, callback) ->
  exports.byUsername username, (account) ->
    if account
      return callback account

    exports.byEmail username, callback

# @return bool
exports.matchPasswd = (account, passwd) ->
  return auth.hashPasswd(passwd, account.passwd_salt) == account.passwd

exports.inGroup = (account, group) ->
  return group in account.group
