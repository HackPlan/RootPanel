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
