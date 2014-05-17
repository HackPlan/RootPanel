child_process = require 'child_process'
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
  unless req.body.passwd or not /^[A-Za-z0-9\-_]+$/.test req.body.passwd
    return res.json 400, error: 'invalid_passwd'

  child_process.exec "echo '#{req.account.username}:#{req.body.passwd}' | sudo chpasswd", (err, stdout, stderr) ->
    throw err if err
    res.json {}
