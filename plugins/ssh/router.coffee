{child_process, express} = app.libs
{requireInService} = app.middleware
{cache, logger} = app

module.exports = exports = express.Router()

ssh = require './ssh'

exports.use requireInService 'ssh'

exports.post '/update_password', (req, res) ->
  unless /^.+$/.test req.body.password
    return res.error 'invalid_password'
    
  ssh.updatePassword req.account, req.body.password, ->
    res.json {}

exports.post '/kill', (req, res) ->
  pid = parseInt req.body.pid

  ssh.killProcess req.account, pid, ->
    res.json {}
