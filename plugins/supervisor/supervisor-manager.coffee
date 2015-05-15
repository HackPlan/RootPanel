validator = require 'validator'

status_mapping =
  STOPPED: 'stopped'
  STARTING: 'running'
  RUNNING: 'running'
  BACKOFF: 'stopped'
  STOPPING: 'running'
  EXITED: 'stopped'
  FATAL: 'stopped'
  UNKNOWN: 'stopped'

module.exports = class SupervisorManager
  constructor: (@server) ->

  writeConfig: (name, programs) ->
    @server.writeFile configPath(name), renderConfig(programs), mode: 640

  removeConfig: (name) ->
    @server.command "sudo rm #{configPath name}"

  updateProgram: ({autostart, user, name}) ->
    @server.command('sudo supervisorctl update').then =>
      if autostart
        @server.command "sudo supervisorctl start #{user}-#{name}"

  controlProgram: ({user, name}, action) ->
    @server.command "sudo supervisorctl #{action} #{user}-#{name}"

  programsStatus: ->
    @server.command('sudo supervisorctl status').then ({stdout}) ->
      return stdout.split('\n')[... -1].map (line) ->
        [$, name, status, pid, uptime] = line.match /^(\S+)\s+(\S+)\s+pid (\d+), uptime (.*)/

        return {
          pid: pid
          name: name
          uptime: uptime
          status: status_mapping[status]
        }

configPath = (name) ->
  return "/etc/supervisor/conf.d/#{name}.conf"

renderConfig = (programs) ->
  renderProgram = (program) ->
    configuration = """
      [program:#{program.user}-#{program.name}]
      user = #{program.user}
      command = #{program.command}
      autostart = #{program.autostart}
      autorestart = #{program.autorestart}
      redirect_stderr = true\n
    """

    if program.directory
      configuration += "directory = #{program.directory}\n"

    if program.stdout_logfile != false
      configuration += "stdout_logfile = /home/#{user}/supervisor-#{name}.log\n"

    return configuration

  return programs.map(renderProgram).join '\n'
