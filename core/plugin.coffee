path = require 'path'

i18n = require './i18n'
config = require './config'

exports.get = (name) ->
  return require path.join(__dirname, "../plugin/#{name}")

exports.loadPlugins = (app) ->
  for name in config.plugin.availablePlugin
    i18n.loadPlugin path.join(__dirname, "../plugin/#{name}/locale"), name

    plugin = exports.get name

    if plugin.action
      app.use ('/plugin/' + name), plugin.action
