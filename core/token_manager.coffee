mAccount = require './model/account'

# @param callback(token)
exports.generateAvailableToken = (callback) ->
  token = exports.randomSalt()

  exports.findOne
    'tokens.token': token
  , (err, result) ->
    if result
      exports.generateAvailableToken callback
    else
      callback token

# @param callback(token)
exports.createToken = (account, type, payload, callback) ->
  exports.generateAvailableToken (token) ->
    exports.update _id: account._id,
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
exports.revokeToken = (token, payload, callback) ->
  modifier =
    $set:
      'tokens.$.is_available': false

  for k, v of payload
    modifier.$set["tokens.$.payload.#{k}"] = v

  exports.update 'tokens.token': token, modifier, (err, rows) ->
    callback rows > 0

# @param callback(type, account)
exports.authenticate = (token, callback) ->
  unless token
    return callback null

  exports.findAndModify 'tokens.token': token, {},
    $set:
      'tokens.$.updated_at': new Date()
  , (err, account) ->
    matched_token = _.find account?.tokens, (i) ->
      return i.token == token

    callback matched_token.type, account
