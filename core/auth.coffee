crypto = require 'crypto'

exports.sha256 = (data) ->
  if not data
    return null
  return crypto.createHash('sha256').update(data).digest('hex')

exports.randomSalt = ->
  return exports.sha256 crypto.randomBytes 256

exports.hashPasswd = (passwd, passwd_salt) ->
  return exports.sha256(exports.sha256(passwd) + passwd_salt)
