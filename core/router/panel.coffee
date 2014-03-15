Account = require '../model/Account'

module.exports =
  get:
    '/': (req, res) ->
      res.redirect '/panel/'

    '/panel/': (req, res) ->
      Account.authenticate req.token, (account) ->
        res.render 'panel',
          account: account
