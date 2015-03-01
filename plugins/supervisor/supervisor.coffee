{async, child_process, fs, _} = app.libs
{logger} = app

SupervisorPlugin = require './index'

exports.removePrograms = (account, callback) ->
  async.each account.pluggable.supervisor.programs, (program, callback) ->
    exports.removeConfig account, program, ->
      callback()
  , ->
    exports.updateProgram account, null, ->
      callback()

exports.updateProgram = (account, program, callback) ->
  child_process.exec 'sudo supervisorctl update', (err) ->
    logger.error err if err

    if program and program.autostart
      child_process.exec "sudo supervisorctl start #{program.program_name}", (err) ->
        logger.error err if err
        callback()
    else
      callback()

exports.writeConfig = (account, program, callback) ->
  SupervisorPlugin.renderTemplate 'program.conf',
    account: account
    program: program
  , (configure) ->
    SupervisorPlugin.writeConfigFile "/etc/supervisor/conf.d/#{program.program_name}.conf", configure, ->
      callback()

exports.removeConfig = (account, program, callback) ->
  child_process.exec "sudo rm /etc/supervisor/conf.d/#{program.program_name}.conf", (err) ->
    logger.error err if err
    callback()

# @param action: start|stop|restart
exports.programControl = (account, program, action, callback) ->
  child_process.exec "sudo supervisorctl #{action} #{program.program_name}", (err) ->
    logger.error err if err
    callback()

exports.programsStatus = (callback) ->
  child_process.exec 'sudo supervisorctl status', (err, stdout) ->
    lines = stdout.split '\n'
    lines = lines[... lines.length - 1]

    callback _.map lines, (line) ->
      [__, name, status, info] = line.match /^(\S+)\s+(\S+)\s+(.*)/

      if name.match /^([^:]+):/
        [__, name] = name.match /^([^:]+):/

      status_mapping =
        STOPPED: 'stopped'
        STARTING: 'running'
        RUNNING: 'running'
        BACKOFF: 'stopped'
        STOPPING: 'running'
        EXITED: 'stopped'
        FATAL: 'stopped'
        UNKNOWN: 'stopped'

      return {
        name: name
        original_status: status
        status: status_mapping[status]
        info: info
      }
