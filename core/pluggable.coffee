async = require 'async'
path = require 'path'
harp = require 'harp'
fs = require 'fs'
_ = require 'underscore'

i18n = require './i18n'
config = require './../config'

exports.plugins = {}

exports.hooks =
  account:
    # filter: function(account, callback(is_allow))
    username_filter: []
    # filter: function(account, callback)
    before_register: []

  view:
    layout:
      # href, target, body
      menu_bar: []
      # path
      scripts: []
      # path
      styles: []

    panel:
      # path
      scripts: []
      # generator: function(account, callback)
      widgets: []
      # path
      styles: []
      # name
      switch_buttons: []

exports.registerHook = (hook_name, plugin, payload) ->
  keys = hook_name.split '.'
  last_key = keys.pop()

  pointer = exports.hooks

  for item in keys
    if pointer[item] == undefined
      throw new Error 'Invalid hook name'
    else
      pointer = pointer[item]

  pointer[last_key].push _.extend payload
    plugin_info: plugin

exports.selectHook = (account, hook_name) ->
  keys = hook_name.split '.'

  pointer = exports.hooks

  for item in keys
    if pointer[item] == undefined
      throw new Error 'Invalid hook name'
    else
      pointer = pointer[item]

  selected_hooks = []

  for hook in pointer
    if hook.plugin_info.type == 'service'
      selected_hooks.push hook
    else if hook.plugin_info.name in account.billing.services
      selected_hooks.push hook

  return selected_hooks

exports.initializePlugins = (callback) ->
  initializePlugin = (name, callback) ->
    plugin_path = path.join __dirname, "../plugin/#{name}"
    plugin = require plugin_path

    if fs.existsSync path.join(plugin_path, 'locale')
      i18n.loadForPlugin plugin

    if fs.existsSync path.join(plugin_path, 'static')
      app.use harp.mount("/plugin/#{name}", path.join(plugin_path, 'static'))

    if plugin.router
      app.use ("/plugin/#{name}"), plugin.router

    callback plugin

  initializeExtension = (plugin, callback) ->
    callback()

  initializeService = (plugin, callback) ->
    callback()

  async.parallel [
    (callback) ->
      async.each config.plugin.available_extensions, (name, callback) ->
        initializePlugin name, (plugin) ->
          initializeExtension plugin, callback
      , callback

    (callback) ->
      async.each config.plugin.available_services, (name, callback) ->
        initializePlugin name, (plugin) ->
          initializeService plugin, callback
      , callback
  ], callback

exports.writeConfig = (path, content, callback) ->
  tmp.file
    mode: 0o750
  , (err, filepath, fd) ->
    fs.writeSync fd, content, 0, 'utf8'
    fs.closeSync fd

    child_process.exec "sudo cp #{filepath} #{path}", (err) ->
      throw err if err

      fs.unlink path, ->
        callback()

exports.sudoSu = (account, command) ->
  return "sudo su #{account.username} -c '#{command}'"
