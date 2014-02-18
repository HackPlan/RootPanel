Model = require './Model'
auth = require '../auth'
assert = require 'assert'
db = require '../db'

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
