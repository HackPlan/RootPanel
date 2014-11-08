{child_process, fs, _} = app.libs

supervisor_plugin = require './index'

exports.removePrograms = (account, callback) ->

exports.programSummary = (program) ->

exports.updateProgram = (account, program, callback) ->

exports.writeConfig = (account, program, callback) ->
  program_name = "@#{account.username}-#{program.name}"

  supervisor_plugin.renderTemplate 'program.conf',
    name_prefix: '@'
    account: account
    program: program
  , (configure) ->
    supervisor_plugin.writeConfigFile "/etc/supervisor/conf.d/#{program_name}.conf", configure, ->
      callback()

exports.removeConfig = (account, program, callback) ->

exports.programControl = (account, program, action, callback) ->

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
