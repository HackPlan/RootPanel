Model = require './Model'
auth = require '../auth'
assert = require 'assert'
db = require '../db'
_ = require 'underscore'

module.exports = class User extends Model
  @table : ->
    'users'

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
    db.open (err,db)=>
      @collection(db).insert attributes, {}, (err, result) ->
        assert.equal null,err

        if callback
          result = new User result[0]
          db.close()
          callback null, result

  save : ->
    console.log 'asd'

  set : (key, value = null) ->
    if (_.isObject key) is 'object' then attrs = key else attrs[key] = value
    @attributes[k] = v for k, v of attrs
    @
  get : (attr)->
    @attributes[attr]