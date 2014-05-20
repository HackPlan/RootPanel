express = require 'express'

{requestAdminAuthenticate} = require './middleware'

mAccount = require '../model/account'

module.exports = exports = express.Router()

exports.get '/', requestAdminAuthenticate, (req, res) ->
  mAccount.find {}, {}, (accounts) ->
    res.render 'admin/index',
      accounts: accounts
