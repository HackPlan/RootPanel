child_process = require 'child_process'
express = require 'express'

service = require './service'

{requestAuthenticate} = require '../../core/router/middleware'

mAccount = require '../../core/model/account'

module.exports = exports = express.Router()

exports.use (req, res, next) ->
  req.inject [requestAuthenticate], ->
    unless 'phpfpm' in req.account.attribute.services
      return res.error 'not_in_service'

    next()

exports.post '/switch', (req, res) ->
  unless req.body.enable in [true, false]
    return res.err 'invalid_enable'

  mAccount.update _id: account._id,
    $set:
      'attribute.plugin.phpfpm.is_enable': false
  , ->
    callback()

    service.switch req.account, req.body.enable, ->
      res.json {}
