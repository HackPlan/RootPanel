mAccount = require '../model/account'

module.exports =
  get:
    '/admin/': (req, res) ->
      mAccount.authenticate req.token, (account) ->
        unless account
          return res.redirect '/account/login/'

        unless mAccount.inGroup account, 'root'
          return res.send 403

        mAccount.find {}, {}, (accounts) ->
          res.render 'admin/index',
            account: account
            accounts: accounts

  post:{}
