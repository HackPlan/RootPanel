Model = require './Model'
auth = require '../auth'
db = require '../db'
_ = require 'underscore'

module.exports = class User extends Model
  #传入model
  # @validateData:
  #   group: ['admin','user','trial']
  # 必须重写
  @create: (data) ->
    new User data
  # 注册新用户
  # @callback的第二个参数是新注册的model
  # 用法：
  #     User.register 'wangzi','wangzi@gmail','wangzi',(err,result)->
  #       console.log result
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

  # @param callback(token)
  createToken: (attribute, callback) ->
    # @param callback(token)
    generateToken = (callback) ->
      token = exports.randomSalt()

      User.findOne
        'tokens.token': token
      , (err, result) ->
        throw err if err
        if result
          generateToken callback
        else
          callback token

    generateToken (token) ->
      @update
        $push:
          tokens:
            token: token
            available: true
            created_at: new Date()
            updated_at: new Date()
            attribute: attribute
      , ->
        callback token

  removeToken: (token, callback = null) ->
    @update
      $pull:
        tokens:
          token: token
    , ->
      callback() if callback

  # @return bool
  matchPasswd: (passwd) ->
    return auth.hashPassword(passwd, @data.passwd_salt) == @data.passwd

  @byUsername: (username, callback) ->
    @findOne
      username: username
    , (err, result) ->
      throw err if err
      callback result

  @byEmail: (email, callback) ->
    @findOne
      email: email
    , (err, result) ->
      throw err if err
      callback result

  # 添加分组的功能
  # @group 可以是数组，也可以是字符串，但是必须在['admin','user','trial']中
  # @callback 第一个参数是err,第二个参数是添加分组后的model
  # 用法：
  #     user.addToGroup ['admin','user'],(err,result)->
  #       console.log result
  # 或
  #     user.addToGroup 'admin',(err,result)->
  #       console.log result
  addToGroup: (group,callback) ->
    group = [].push group if not _.isArray group
    # for i in group
      # throw 'unknown group' if i not in @constructor.validateData['group']
    @update $addToSet:
      group:
        $each:group
    ,callback
  #从分组中移除
  # @group [string]，必须在['admin','user','trial']中
  # @callback 第一个参数是err,第二个参数是移除分组后的model
  # 用法：
  #     user.removeFromGroup 'user',(err,result)->
  #       console.log result
  removeFromGroup: (group,callback) ->
    # throw 'group must be string' if not _.isString group
    # throw 'unknown group' if group not in @constructor.validateData['group']
    @update $pull:
      group: group
    ,callback