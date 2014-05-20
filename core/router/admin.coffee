express = require 'express'

{renderAccount} = require './middleware'

mAccount = require '../model/account'

module.exports = exports = express.Router()

exports.get '/', renderAccount, (req, res) ->
  mAccount.find {}, {}, (accounts) ->
    res.render 'admin/index',
      accounts: accounts
