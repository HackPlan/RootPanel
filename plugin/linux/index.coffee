{async, _} = app.libs
{pluggable, config} = app
{requireAuthenticate} = app.middleware
{wrapAsync} = app.utils

exports = module.exports = class LinuxPlugin extends pluggable.Plugin
  @NAME: 'linux'
  @type: 'service'

linux = require './linux'
monitor = require './monitor'

exports.registerHook 'view.layout.menu_bar',
  href: '/public/monitor/'
  t_body: 'plugins.linux.server_monitor'

exports.registerHook 'account.username_filter',
  filter: (username, callback) ->
    linux.getPasswdMap (passwd_map) ->
      if username in _.values passwd_map
        callback false
      else
        callback true

exports.registerHook 'view.panel.styles',
  path: '/plugin/linux/style/panel.css'

exports.registerHook 'view.panel.widgets',
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

exports.registerHook 'account.resources_limit_changed',
  always_notice: true
  filter: (account, callback) ->
    linux.setResourceLimit account, callback

exports.registerServiceHook 'enable',
  filter: (req, callback) ->
    linux.createUser req.account, callback

exports.registerServiceHook 'disable',
  filter: (req, callback) ->
    linux.deleteUser req.account, callback

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

if config.plugins.linux.monitor_cycle
  monitor.run()
