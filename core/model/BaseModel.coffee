$ = (require "mongous").Mongous
config = require "../config"
class BaseModel
	constructor : ->

	@dbHandle : ->
		$ "#{config.db.name}.#{@table()}"

	save : ->
		@constructor.dbHandle().save(@data)

	@findByName: (name,callback) ->
		@dbHandle().find 1,
			name : name
		,callback

module.exports = BaseModel