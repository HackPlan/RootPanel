{pluggable, config} = app

linux = require './linux'

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
    exports.render 'widget', req,
      resources_usage: null
      storage_usage: null
    , callback

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
