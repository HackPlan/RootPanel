$ = (require "mongous").Mongous
config = require "../config"
class BaseModel
	constructor : ->
		@constructor.errors = {}
	@dbHandle : ->
		$ "#{config.db.name}.#{@table()}"

	save : ->
		@constructor.resetErrors()
		@constructor.dbHandle().save(@data) if @validate()

	validate : ->
		true
	@findByName: (name,callback,num = 1) ->
		@resetErrors()
		@dbHandle().find num,
			name : name
		,callback
	@findBy : (obj,callback,num = 1) ->
		@resetErrors()
		@dbHandle().find num,obj,callback

	@getErrors : ->
		@errors

	@resetErrors : ->
		@errors = {}
	@setErrors : (k,v)->
		@errors[k] = v
		console.log v
	required : (arr)->
		@constructor.setErrors key, "#{key}不能为空" for key in arr when !@data[key]

	exsited : (k,v)->
		# for k, v of obj
		temp  = {}
		temp[k] = v
		# 	@constructor.findBy temp,(r)=>
		# 		if r.documents.length isnt 0
		# 			@constructor.setErrors k, "#{k}已经存在"
		@constructor.findBy temp,(r)=>
			if r.documents.length isnt 0
				@constructor.setErrors k, "#{k}已经存在"

module.exports = BaseModel