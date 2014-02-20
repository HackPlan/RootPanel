Model = require './Model'
auth = require '../auth'
db = require '../db'
_ = require 'underscore'

module.exports = class User extends Model
  @validateData:
    group: ['admin','user','trial']

  @create: (data) ->
    new User data

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
    @insert data, callback

  addToGroup: (group,callback) ->
    group = [].push group if not _.isArray group
    for i in group
      throw 'bad group' if i not in @constructor.validateData['group']
    @data.group = group
    @update callback