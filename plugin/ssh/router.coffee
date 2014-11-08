{child_process, express} = app.libs
{requireInService} = app.middleware
{cache, logger} = app

module.exports = exports = express.Router()

exports.use requireInService 'ssh'

exports.post '/update_password', (req, res) ->
  unless /^.+$/.test req.body.password
    return res.error 'invalid_password'

  chpasswd = child_process.spawn 'sudo', ['chpasswd']
  chpasswd.stdin.end "#{req.account.username}:#{req.body.password}"

  chpasswd.on 'error', logger.error

  chpasswd.on 'exit', ->
    res.json {}

exports.post '/kill', (req, res) ->
  pid = parseInt req.body.pid

  child_process.exec "sudo su #{req.account.username} -c 'kill #{pid}'", (err) ->
    logger.error err if err

    cache.delete 'linux.getProcessList', ->
      res.json {}
