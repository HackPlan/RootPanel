_ = require 'underscore'

utils = require './utils'

mAccount = require './model/account'

# @param callback(token)
exports.generateToken = (callback) ->
  token = utils.randomSalt()

  mAccount.findOne
    'tokens.token': token
  , (err, result) ->
    if result
      exports.generateToken callback
    else
      callback token

# @param callback(token)
exports.createToken = (account, type, payload, callback) ->
  exports.generateToken (token) ->
    mAccount.update {_id: account._id},
      $push:
        tokens:
          type: type
          token: token
          is_available: true
          created_at: new Date()
          updated_at: new Date()
          payload: payload
    , ->
      callback token

# @param payload must be flat
# @param callback(is_found)
exports.revokeToken = (token, callback) ->
  mAccount.update {'tokens.token': token},
    $pull:
      tokens:
        token: token
  , (err, rows) ->
    callback rows > 0

# @param callback(type, account)
exports.authenticate = (token, callback) ->
  unless token
    return callback null

  mAccount.findAndModify 'tokens.token': token, {},
    $set:
      'tokens.$.updated_at': new Date()
  , (err, account) ->
    matched_token = _.findWhere account.tokens,
      token: token

    callback matched_token, account
