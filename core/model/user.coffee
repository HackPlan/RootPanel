BaseModel = require "./BaseModel"
crypto = require "crypto"
class User extends BaseModel
	constructor : (@data = {name : null}) ->
		super()
		@data.passwd_salt = crypto.createHash('sha256').digest('hex')
		@data.signup_at = Date.parse new Date
		@data.group = []
		@data.tokens = []
		@data.setting = {}
		@data.attribute = {}
	@table : ->
		'users'
module.exports = User