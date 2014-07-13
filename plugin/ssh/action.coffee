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

exports.post '/update_password/', (req, res) ->
  unless req.body.password or not /^[A-Za-z0-9\-_]+$/.test req.body.password
    return res.error 'invalid_password'

  plugin.systemOperate (callback) ->
    child_process.exec "echo '#{req.account.username}:#{req.body.password}' | sudo chpassword", (err, stdout, stderr) ->
      throw err if err
      callback()
  , ->
    res.json {}
