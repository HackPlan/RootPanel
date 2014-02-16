$ = (require "mongous").Mongous
config = require "../config"
EventProxy = require 'eventproxy'
class BaseModel
	constructor : ->
		@constructor.errors = {}
		@constructor.ep = new EventProxy()
	@dbHandle : ->
		$ "#{config.db.name}.#{@table()}"

	save : ->
		@validate (validated)->
			if validated
				@constructor.resetErrors()
				@constructor.dbHandle().save(@data)
	#如验证需重写
	validate : (callback)->
		@constructor.ep.all 'validate',callback
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
		@constructor.findBy temp,(r)=>
			if r.documents.length isnt 0
				@constructor.setErrors k, "#{k}已经存在"
				@constructor.ep.emit "exsited_#{k}",false
			@constructor.ep.emit "exsited_#{k}",true

module.exports = BaseModel