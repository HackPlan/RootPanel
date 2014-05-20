api = require './index'

mAccount = require '../model/account'

module.exports =
  get:
    '/admin/': api.accountAdminAuthenticateRender (req, res, account, renderer) ->
      mAccount.find {}, {}, (accounts) ->
        renderer 'admin/index',
          accounts: accounts

  post:{}
