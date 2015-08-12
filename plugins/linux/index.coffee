validator = require 'validator'

{requireAuthenticate} = root.middleware

module.exports = class Linux extends root.Plugin
  activate: ->
    @injector.view 'layout',
      filename: @resolve 'view/layout'
      locals:
        linux: @

    @injector.router('/public/monitor').get '/node?', requireAuthenticate, (req, res) =>
      server = @getLinuxServer req.params.node

      Q.all
        system: server.system()
        storage: server.getStorageUsages()
        processes: server.getProcessList()
        memory: server.getMemoryUsages()
      .then (statistics) ->
        res.render @resolve('view/monitor'),
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

      actions: [
        setPassword:
          handler: ({node, options: {user}}, {passowrd}) =>
            unless validator.isPassword passowrd
              throw new Error 'invalid_password'

            @getLinuxServer(node).setPassword user, password

        killProcess:
          handler: ({node, options: {user}}, {pid}) =>
            @getLinuxServer(node).killProcess user, parseInt(pid)

      ]

    @injector.widget 'panel',
      repeating:
        every: 'linux'
      generator: (account, component) ->
        root.views.render @resolve 'view/widget'

    if @config.monitor_cycle
      @monitors = root.servers.all().map ({name}) =>
        return new LinuxMonitoring @getLinuxServer(name),
          monitor_cycle: @config.monitor_cycle

  getLinuxServer: (node) ->
    if node
      return new LinuxServer root.servers.byName node
    else
      return new LinuxServer root.servers.master()

LinuxServer = require './linux-server'
LinuxMonitoring = require './linux-monitoring'
