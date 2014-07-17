child_process = require 'child_process'

plugin = require '../../core/plugin'

{requestAuthenticate} = require '../../core/router/middleware'

mAccount = require '../../core/model/account'

module.exports = exports = express.Router()

exports.use (req, res, next) ->
  req.inject [requestAuthenticate], ->
    unless 'ssh' in req.account.attribute.services
      return res.error 'not_in_service'

    next()

exports.post '/update_password', (req, res) ->
  unless req.body.password or not /^[A-Za-z0-9\-_]+$/.test req.body.password
    return res.error 'invalid_password'

  child_process.exec "echo '#{req.account.username}:#{req.body.password}' | sudo chpasswd", (err, stdout, stderr) ->
    throw err if err
    res.json 200, {}

exports.post '/kill', (req, res) ->
  pid = parseInt req.body.pid
  child_process.exec "sudo su #{req.account.username} -c 'kill #{pid}}'", (err, stdout, stderr) ->
    throw err if err
    res.json {}
