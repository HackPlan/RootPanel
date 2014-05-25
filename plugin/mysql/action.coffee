express = require 'express'

mAccount = require '../../core/model/account'

module.exports = exports = express.Router()

exports.use (req, res, next) ->
  mAccount.authenticate req.token, (account) ->
    unless account
      return res.json 400, error: 'auth_failed'

    unless 'ssh' in account.attribute.service
      return res.json 400, error: 'not_in_service'

    req.account = account
    next()

exports.post '/update_passwd/', (req, res) ->
  res.json {}
