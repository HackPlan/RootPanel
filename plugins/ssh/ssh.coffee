{child_process} = app.libs
{cache, logger} = app

exports.updatePassword = (account, password, callback) ->
  chpasswd = child_process.spawn 'sudo', ['chpasswd']
  chpasswd.stdin.end "#{account.username}:#{password}"

  chpasswd.on 'error', logger.error

  chpasswd.on 'exit', ->
    callback()

exports.killProcess = (account, pid, callback) ->
  child_process.exec "sudo su #{account.username} -c 'kill #{pid}'", (err) ->
    logger.error err if err

    cache.delete 'linux.getProcessList', ->
      callback()
