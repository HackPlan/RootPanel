_ = require 'underscore'
async = require 'async'

{pluggable, config} = app
{requireAuthenticate} = app.middleware
{wrapAsync} = app.utils

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
    resources_usage: wrapAsync linux.getResourceUsageByAccounts
    system: wrapAsync linux.getSystemInfo
    storage: wrapAsync linux.getStorageInfo
    process_list: wrapAsync linux.getProcessList

  , (err, result) ->
    exports.render 'monitor', req, result, (html) ->
      res.send html

monitor.run()
