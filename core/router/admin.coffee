express = require 'express'

{requestAdminAuthenticate, renderAccount} = require './middleware'

mAccount = require '../model/account'

module.exports = exports = express.Router()

exports.get '/', requestAdminAuthenticate, renderAccount, (req, res) ->
  mAccount.find({}).toArray (err, accounts) ->
    res.render 'admin/index',
      accounts: accounts

exports.post '/create_payment', requestAdminAuthenticate, (req, res) ->
