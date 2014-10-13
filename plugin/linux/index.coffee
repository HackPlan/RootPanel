{pluggable, config} = app
{requireAuthenticate} = app.middleware

linux = require './linux'
monitor = require './monitor'

module.exports = pluggable.createHelpers exports =
  name: 'linux'
  type: 'service'

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
    linux.getResourceUsageByAccounts (resources_usage) ->
      exports.render 'widget', req,
        resources_usage: resources_usage[req.account.username]
      , (html) ->
        callback html

exports.registerHook 'account.resources_limit_changed',
  action: (account, callback) ->
    linux.setResourceLimit account, callback

exports.registerServiceHook 'enable',
  action: (req, callback) ->
    linux.createUser req.account, ->
      linux.setResourceLimit account, callback

exports.registerServiceHook 'disable',
  action: (req, callback) ->
    linux.deleteUser req.account, callback

app.get '/public/monitor', requireAuthenticate, (req, res) ->
  async.parallel
    resources_usage: (callback) ->
      linux.getResourceUsageByAccounts (resources_usage) ->
        callback null, resources_usage

    system: (callback) ->
      linux.getSystemInfo (system_info) ->
        callback null, system_info

    storage: (callback) ->
      linux.getStorageInfo (storage_info) ->
        callback null, storage_info

    process_list: (callback) ->
      linux.getProcessList (process_list) ->
        callback null, process_list

  , (err, result) ->
    exports.render 'monitor', req, result, (html) ->
      res.send html

monitor.run()
