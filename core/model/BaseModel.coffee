$ = (require "mongous").Mongous
config = require "../config"
EventProxy = require 'eventproxy'
nullFunc = ->
firstCapital = (str) ->
	return str.replace /\b\w+\b/g,(word) ->
		return word.substring(0,1).toUpperCase() + word.substring 1

class BaseModel
	constructor : ->
		@constructor.errors = {}
		@constructor.ep = new EventProxy()
		@constructor.searchBy = ''
	@dbHandle : ->
		$ "#{config.db.name}.#{@table()}"

	save : (callback = nullFunc)->
		# @constructor.resetErrors()
		@validate (validated)=>
			err = @constructor.errors
			if validated
				searchBy = @constructor.searchBy
				@constructor.resetErrors()
				@constructor.dbHandle().save @data
				@constructor["findBy#{firstCapital searchBy}"] @data[searchBy],(r)=>
					@data = r.documents[0]
					callback(null,@data)
			else
				callback(err,null)
	#如验证需重写
	validate : (callback)->
		@constructor.ep.once 'validate',callback
	remove : ->
		@constructor.dbHandle().remove _id: @data._id

	update : (update,upsert = false, multi = true)->
		@constructor.update {_id : @data._id},update,upsert,multi

	@update : (what,update,upsert = false,multi = true) ->
		@dbHandle().update what,update,upsert,multi
	@findById : (id,callback) ->
		@dbHandle().find 1,{_id : id},callback
	@findBy : (obj,callback,num = 1) ->
		@dbHandle().find num,obj,callback
	@getErrors : ->
		@errors

	@resetErrors : ->
		@errors = {}
	@setErrors : (k,v)->
		@errors[k] = v
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