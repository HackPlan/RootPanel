Model = require './Model'
auth = require '../auth'
db = require '../db'
_ = require 'underscore'

module.exports = class User extends Model
  @validateData:
    group: ['admin','user','trial']
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
  # 添加分组的功能
  # @group 可以是数组，也可以是字符串，但是必须在['admin','user','trial']中
  # @callback 第一个参数是err,第二个参数是添加分组后的model
  # 用法：
  #     user.addToGroup ['admin','users'],(err,result)->
  #       console.log result
  # 或
  #     user.addToGroup 'admin',(err,result)->
  #       console.log result
  addToGroup: (group,callback) ->
    group = [].push group if not _.isArray group
    for i in group
      throw 'bad group' if i not in @constructor.validateData['group']
    @update $addToSet:
      group:
        $each:group
    ,callback