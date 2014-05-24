child_process = require 'child_process'
express = require 'express'

mAccount = require '../../core/model/account'

module.exports = exports = express.Router()

exports.use (req, res, next) ->
  mAccount.authenticate req.token, (account) ->
    unless account
      return res.json 400, error: 'auth_failed'

    unless 'phpfpm' in account.attribute.service
      return res.json 400, error: 'not_in_service'

    req.account = account
    next()

exports.post '/enable/', (req, res) ->
  res.json {}
