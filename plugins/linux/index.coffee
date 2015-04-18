module.exports = class Linux
  constructor: (@injector, {@monitor_cycle}) ->
    {requireAuthenticate} = root.middleware

    @injector.view 'layout',
      filename: __dirname + '/view/layout'
      locals: linux: @

    @injector.router('/public/monitor').get '/node?', requireAuthenticate, (req, res) =>
      server = @getLinuxServer req.params.node

      Q.all([
        server.system()
        server.getStorageUsages()
        server.getProcessList()
        server.getMemoryUsages()
      ]).then ([system, storage, processes, memory]) ->
        res.render __dirname + '/view/monitor',
          system: system
          storage: storage
          processes: processes
          memory: memory

    @injector.component 'linux',
      initialize: ({node, options: {user}}) =>
        @getLinuxServer(node).createUser user

      destroy: ({node, options: {user}}) =>
        @getLinuxServer(node).deleteUser user

      reconfigure: (component) ->

    @injector.widget 'panel',
      repeating:
        components:
          linux: every: true
      generator: (account, component) ->
        root.views.render __dirname + '/view/widget'

    if @monitor_cycle
      @monitors = root.servers.all().map ({name}) =>
        return new LinuxMonitoring @getLinuxServer(name),
          monitor_cycle: @monitor_cycle

  getLinuxServer: (node) ->
    if node
      return new LinuxServer root.servers.byName node
    else
      return new LinuxServer root.servers.master()

LinuxServer = require './linux-server'
LinuxMonitoring = require './linux-monitoring'
