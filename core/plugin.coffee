child_process = require 'child_process'
path = require 'path'
harp = require 'harp'
tmp = require 'tmp'
fs = require 'fs'

i18n = require './i18n'
config = require './../config'

app.plugins = {}

exports.get = (name) ->
  return require path.join(__dirname, "../plugin/#{name}")

exports.loadPlugins = (app) ->
  for name in config.plugin.availablePlugin
    i18n.loadPlugin path.join(__dirname, "../plugin/#{name}/locale"), name

    plugin = exports.get name

    app.use harp.mount('/plugin/' + name, path.join(path.join(__dirname, "../plugin/#{name}"), 'static'))

    if plugin.action
      app.use ('/plugin/' + name), plugin.action

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
