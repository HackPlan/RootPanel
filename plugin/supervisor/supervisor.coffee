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

exports.programSummary = (program) ->
  summary = "autostart:#{program.autostart};autorestart:#{program.autorestart}"

  if program.directory
    summary += ";directory:#{program.directory}"

  return summary

exports.updateProgram = (account, program, callback) ->
  child_process.exec 'sudo supervisor update', (err) ->
    logger.error err if err

    if program and program.autostart
      child_process.exec "sudo supervisor start #{program.program_name}", (err) ->
        logger.error err if err
        callback()
    else
      callback()

exports.writeConfig = (account, program, callback) ->
  SupervisorPlugin.renderTemplate 'program.conf',
    name_prefix: '@'
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
  child_process.exec "sudo supervisor #{action} #{program.program_name}", (err) ->
    logger.error err if err
    callback()

exports.programsStatus = (callback) ->
  child_process.exec 'sudo supervisor status', (err, stdout) ->
    callback _.map stdout.split('\n'), (line) ->
      [name, status] = line.split '\s'

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
      }
