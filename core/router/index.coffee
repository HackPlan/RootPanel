User = require '../model/User'
routers =
  get:
    '/user/signup/': (req, res) ->
      res.render 'signup'

    '/user/login/': (req, res) ->
      res.render 'login'

    '/': (req,res) ->
    	User.register 'wangzi','wangzi@gmail','wangzi',(err,results) ->
    		console.log results
    		results.remove()
    		res.end()

  post: {}

for item in ['user']
  for url, controller of require("./" + item)
    routers.post[url] = controller

module.exports = routers
