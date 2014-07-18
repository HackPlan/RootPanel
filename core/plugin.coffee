child_process = require 'child_process'
path = require 'path'
tmp = require 'tmp'
fs = require 'fs'

i18n = require './i18n'
config = require './../config'
{requestAuthenticate} = require './router/middleware'

exports.get = (name) ->
  return require path.join(__dirname, "../plugin/#{name}")

exports.loadPlugins = (app) ->
  for name in config.plugin.availablePlugin
    i18n.loadPlugin path.join(__dirname, "../plugin/#{name}/locale"), name

    plugin = exports.get name

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
        callback
