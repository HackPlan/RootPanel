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
      callback username in _.values passwd_map

exports.registerHook 'view.panel.styles',
  path: '/plugin/linux/style/panel.css'

exports.registerHook 'view.panel.widgets',
  generator: (req, callback) ->

exports.registerServiceHook 'enable',
  action: (req, callback) ->

exports.registerServiceHook 'disable',
  action: (req, callback) ->
