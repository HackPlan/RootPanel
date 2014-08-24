child_process = require 'child_process'
path = require 'path'
harp = require 'harp'
tmp = require 'tmp'
fs = require 'fs'

i18n = require './i18n'
config = require './../config'

app.plugins = {}

app.view_hook =
  menu_bar: []

app.view_style = []

exports.get = (name) ->
  return require path.join(__dirname, "../plugin/#{name}")

exports.loadPlugin = (name) ->
  plugin_path = path.join(__dirname, "../plugin/#{name}")
  plugin = require plugin_path

  if fs.existsSync path.join(plugin_path, 'locale')
    i18n.loadPlugin path.join(plugin_path, 'locale'), name

  if fs.existsSync path.join(plugin_path, 'static')
    app.use harp.mount('/plugin/' + name, path.join(plugin_path, 'static'))

  if plugin.layout?.style
    app.view_style.push "/plugin/#{name}#{plugin.layout.style}"

  if plugin.action
    app.use ('/plugin/' + name), plugin.action

exports.loadPlugins = ->
  for name in config.plugin.available_services
    exports.loadPlugin name

  for name in config.plugin.available_extensions
    exports.loadPlugin name

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
