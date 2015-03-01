{async, _} = app.libs
{requireAuthenticate} = app.middleware
{wrapAsync} = app.utils

linux = require './linux'
monitor = require './monitor'

plugin = app.extends.plugin.register
  name: 'linux'

  initialize: ->
    app.express.get '/public/monitor', requireAuthenticate, (req, res) =>
      async.parallel
        resources_usage: (callback) ->
          linux.getResourceUsageByAccounts (result) ->
            callback null, result
        system: wrapAsync linux.getSystemInfo
        storage: wrapAsync linux.getStorageInfo
        process_list: wrapAsync linux.getProcessList
        memory: wrapAsync linux.getMemoryInfo

      , (err, result) =>
        logger.error err if err
        @render 'monitor', req, result, (err, html) ->
          res.send html

  started: ->
    if @config.monitor_cycle
      monitor.run()

plugin.registerHook 'view.layout.menu_bar',
  href: '/public/monitor/'
  t_body: 'server_monitor'

plugin.registerHook 'account.username_filter',
  filter: linux.isUsernameAvailable

component = plugin.registerComponent
  name: 'linux'

  initialize: linux.createUser
  destroy: linux.deleteUser

component.registerHookEveryNode 'account.resources_limit_changed',
  filter: linux.setResourceLimit

component.registerHookOnce 'view.panel.styles',
  path: '/plugin/linux/style/panel.css'

component.registerHookEvery 'view.panel.widgets',
  generator: (account, component, callback) ->
    linux.getResourceUsageByAccount account, (resources_usage) =>
      resources_usage ?=
        username: account.username
        cpu: 0
        memory: 0
        storage: 0
        process: 0

      @plugin.render 'widget', @req,
        usage: resources_usage
        limit:
          cpu: 144
          storage: 520
          transfer: 39
          memory: 27
      , callback
