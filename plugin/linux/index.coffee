{async, _} = app.libs
{pluggable, config} = app
{requireAuthenticate} = app.middleware
{wrapAsync} = app.utils
{Plugin} = app.classes

linux = require './linux'
monitor = require './monitor'

linuxPlugin = module.exports = new Plugin
  name: 'linux'

  register_hooks:
    'view.layout.menu_bar':
      href: '/public/monitor/'
      t_body: 'server_monitor'

    'account.username_filter':
      filter: linux.isUsernameAvailable

  initialize: ->
    app.express.get '/public/monitor', requireAuthenticate, (req, res) ->
      async.parallel
        resources_usage: (callback) ->
          linux.getResourceUsageByAccounts (result) ->
            callback null, result
        system: wrapAsync linux.getSystemInfo
        storage: wrapAsync linux.getStorageInfo
        process_list: wrapAsync linux.getProcessList
        memory: wrapAsync linux.getMemoryInfo

      , (err, result) ->
        logger.error err if err
        exports.render 'monitor', req, result, (html) ->
          res.send html

  started: ->
    if @config.monitor_cycle
      monitor.run()

linuxPlugin.registerComponent
  name: 'linux'

  initialize: linux.createUser
  destroy: linux.deleteUser

  pickPayload: (info) ->
    return {
      username: info.username
    }

  register_hooks:
    'account.resources_limit_changed':
      repeating: 'every_node'
      filter: linux.setResourceLimit

    'view.panel.styles':
      repeating: 'once'
      path: '/plugin/linux/style/panel.css'

    'view.panel.widgets':
      repeating: 'every'
      generator: (req, callback) ->
        linux.getResourceUsageByAccount req.account, (resources_usage) ->
          resources_usage ?=
            username: req.account.username
            cpu: 0
            memory: 0
            storage: 0
            process: 0

          exports.render 'widget', req,
            usage: resources_usage
          , callback
