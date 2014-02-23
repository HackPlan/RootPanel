crypto = require 'crypto'
assert = require 'assert'
User = require './model/User'

exports.sha256 = (data) ->
  if not data
    return null
  return crypto.createHash('sha256').update(data).digest('hex')

exports.randomSalt = ->
  return exports.sha256 crypto.randomBytes(256)

exports.hashPasswd = (passwd, passwd_salt) ->
  return exports.sha256(exports.sha256(passwd) + passwd_salt)

# @param callback(User)
exports.authenticate = (token, callback) ->
  if not token
    callback null

  User.findOne
    'tokens.token': token
  , (err, result) ->
    throw err if err
    if result
      callback result
    else
      callback null
