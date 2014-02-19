Model = require './Model'
auth = require '../auth'
assert = require 'assert'
db = require '../db'
_ = require 'underscore'

module.exports = class User extends Model
  @create : (attrs,opts = {})->
    return new User attrs,opts

  @register: (username, email, passwd, callback = null) ->
    passwd_salt = auth.randomSalt()

    attributes =
      name: username
      passwd: auth.hashPasswd(passwd, passwd_salt)
      passwd_salt: passwd_salt
      email: email
      signup: new Date()
      group: []
      setting: {}
      attribure: {}
      tokens: []
    @save attributes,callback
