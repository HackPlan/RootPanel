Account = require '../model/account'

module.exports =
  get:
    '/': (req, res) ->
      res.redirect '/panel/'

    '/panel/': (req, res) ->
      account.authenticate req.token, (account) ->
        unless account
          return res.redirect '/account/login/'

        res.render 'panel',
          account: account
