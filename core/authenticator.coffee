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
    matched_token = _.findWhere account?.tokens,
      token: token

    callback matched_token, account
