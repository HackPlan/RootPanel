child_process = require 'child_process'

{requireInService} = app.middleware
{cache} = app

module.exports = exports = express.Router()

exports.use requireInService 'ssh'

exports.post '/update_password', (req, res) ->
  unless req.body.password or not /^[A-Za-z0-9\-_]+$/.test req.body.password
    return res.error 'invalid_password'

  child_process.exec "echo '#{req.account.username}:#{req.body.password}' | sudo chpasswd", (err) ->
    console.error err if err
    res.json {}

exports.post '/kill', (req, res) ->
  pid = parseInt req.body.pid

  child_process.exec "sudo su #{req.account.username} -c 'kill #{pid}'", (err) ->
    console.error err if err

    cache.delete 'linux.getProcessList', ->
      res.json {}
