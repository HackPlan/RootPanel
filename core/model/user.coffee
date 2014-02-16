BaseModel = require "./BaseModel"
crypto = require "crypto"
isEmptyObj = (obj)->
	for key of obj
		return false
	true
class User extends BaseModel
	constructor : (data = {name : null,email:null,passwd:null}) ->
		super()
		passwd_salt = crypto.createHash('sha256').digest('hex')
		@data =
			name : data.name or null
			email : data.email or null
			passwd_salt : passwd_salt
			passwd : crypto.createHash('sha256').update(data.passwd+data.passwd_salt).digest('hex') if data.passwd
			signup_at : Math.round Date.now()/1000
			group : []
			tokens : []
			setting : {}
			attribute : {}
	@table : ->
		'users'
	validate : ->
		# @constructor.findByName @data.name,(r)->
		# 	if r.documents.length isnt 0
		# 		User.errors['name'] = '用户名已存在'
		# @constructor.findBy
		# 	email : @data.email
		# ,(r)->
		# 	if r.documents.length isnt 0
		# 		User.errors['email'] = '邮箱已存在'
		@exsited 'name' ,@data.name
		@exsited 'email', if @data.email is undefined then 'unknow' else @data.email
		@required ['name','passwd','email']
		if isEmptyObj constructor.errors  then false else true


module.exports = User