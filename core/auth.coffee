crypto = require 'crypto'
assert = require 'assert'
User = require './model/User'

exports.sha256 = (data) ->
    return crypto.createHash('sha256').update(data).digest('hex');

exports.randomSalt = ->
  return exports.sha256 crypto.randomBytes(256)

exports.hashPasswd = (passwd, passwd_salt) ->
  return exports.sha256(exports.sha256(passwd) + passwd_salt)

exports.createToken = (user, attribute, callback = undefined) ->
  generateToken = (callback) ->
    token = exports.randomSalt()

    User.find {'tokens.token': token}, (err,result) ->
      assert.equal null,err
      if result.length > 0
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

  User.find {'tokens.token': token}, (err,result) ->
    assert.equal null,err
    if result.length > 0
      callback undefined, result
    else
      callback true, null
