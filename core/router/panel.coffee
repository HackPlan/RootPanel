Account = require '../model/Account'

module.exports =
  get:
    '/': (req, res) ->
      res.redirect '/panel/'

    '/panel/': (req, res) ->
      Account.authenticate req.token, (account) ->
        unless account
          return res.redirect '/account/login/'

        res.render 'panel',
          account: account
