Model = require './Model'
auth = require '../auth'

module.exports = class User extends Model
  collection: ->
    return Model.db.collection 'users'

  @register: (username, email, passwd, callback = null) ->
    passwd_salt = auth.randomSalt()

    data =
      name: username
      passwd: auth.hashPasswd(passwd, passwd_salt)
      passwd_salt: passwd_salt
      email: email
      signup: new Date()
      group: []
      setting: {}
      attribure: {}
      tokens: []

    @collection.insert data, {}, (err, result) ->
      throw err if err

      if callback
        result = new User(result)
        callback null, result
