routers =
  get:
    '/user/signup/': (req, res) ->
      res.render 'signup'

    '/user/login/': (req, res) ->
      res.render 'login'
  post: {}

for item in ['user']
  for url, controller of require("./#{item}")
    routers.post[url] = controller

module.exports = routers
