User = require './User.js'
user = new User
	name : '123'
	email : '123@gmail.com'
	passwd : '123'
result = user.save (err,result)->
	user.remove()


