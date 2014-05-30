child_process = require 'child_process'
express = require 'express'

plugin = require '../../core/plugin'

{requestAuthenticate} = require '../../core/router/middleware'

mAccount = require '../../core/model/account'

module.exports = exports = express.Router()

exports.use (req, res, next) ->
  req.inject [requestAuthenticate], ->
    unless 'ssh' in req.account.attribute.services
      return res.error 'not_in_service'

    next()

exports.post '/update_passwd/', (req, res) ->
  unless req.body.passwd or not /^[A-Za-z0-9\-_]+$/.test req.body.passwd
    return res.json 400, error: 'invalid_passwd'

  plugin.systemOperate (callback) ->
    child_process.exec "echo '#{req.account.username}:#{req.body.passwd}' | sudo chpasswd", (err, stdout, stderr) ->
      throw err if err
      callback()
  , ->
    res.json {}
