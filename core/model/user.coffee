BaseModel = require "./BaseModel"
crypto = require "crypto"
class User extends BaseModel
	constructor : (@data = {name : null}) ->
		super()
		@data.passwd_salt = crypto.createHash('sha256').digest('hex')
	@table : ->
		'users'
module.exports = User