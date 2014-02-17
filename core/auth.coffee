crypto = require 'crypto'

User = require './model/User'

exports.sha256 = (data) ->
    return crypto.createHash('sha256').update(data).digest('hex');

exports.createToken = (user, attribute, callback = undefined) ->
  generateToken = (callback) ->
    token = exports.sha256 crypto.randomBytes(256)

    User.findBy {'tokens.token': token}, (result) ->
      if result.documents.length > 0
        generateToken callback
      else
        callback token

  generateToken (token) ->
    User.update {_id: user.data._id},
      $push:
        tokens:
          token: token
          available: true
          created_at: new Date
          updated_at: new Date
          attribute: attribute
    , ->
      callback(undefined) if callback

exports.authenticate = (token, callback) ->
  if not token
    callback true, null

  User.findBy {'tokens.token': token}, (result) ->
    if result.documents.length > 0
      callback undefined, result
    else
      callback true, null
