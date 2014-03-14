User = require '../model/User'

module.exports =
  get:
    '/': (req, res) ->
      res.redirect '/panel/'

    '/panel/': (req, res) ->
      User.authenticate req.token, (user) ->
        res.render 'panel',
          user: user
