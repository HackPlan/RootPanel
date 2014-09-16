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
    # function(account, callback(is_allow))
    username_filter: []
    # function(account, callback)
    before_register: []

  view:
    layout:
      # object(href, target, body)
      menu_bar: []
      # path
      styles: []

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
