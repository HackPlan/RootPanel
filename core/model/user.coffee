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
		@constructor.searchBy = 'name'
	@table : ->
		'users'
	validate : (callback)->
		super(callback)
		@required ['name','passwd','email']
		@constructor.ep.all 'exsited_name','exsited_email',(name,email)=>
			@constructor.ep.emit 'validate', if name and email then true else false
		@exsited 'name' ,@data.name
		@exsited 'email', @data.email
		# if isEmptyObj constructor.errors  then false else true
	@findByName: (name,callback,num = 1) ->
		@dbHandle().find num,
			name : name
		,callback

module.exports = User