$ = (require "mongous").Mongous
config = require "../config"
class BaseModel
	constructor : ->
		@dbHandle = $ "#{config.db.name}.#{@constructor.name}"

	@findByID : (id)->

	save : ->
		@dbHandle.save(@data)

module.exports = BaseModel