BaseModel = require "./BaseModel"
class User extends BaseModel
	constructor : (@data = {name : null}) ->
		super()
	@table : ->
		'users'
module.exports = User