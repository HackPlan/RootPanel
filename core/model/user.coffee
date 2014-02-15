BaseModel = require "./BaseModel"
class User extends BaseModel
	constructor : (@data = {name : null}) ->
		super()

user = new User
	name : 'asd'
console.log user
user.save()