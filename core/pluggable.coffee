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

  billing:
    # widget_generator: function(account, callback(html))
    payment_methods: []

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

    pay:
      # type, filter: function(account, deposit_log, callback(l_details))
      display_payment_details: []

  service:
    'service_name':
      # action: function(account, callback)
      enable: []
      # action: function(account, callback)
      disable: []

  plugin:
    wiki:
      # t_category, t_title, language, content_markdown
      pages: []

exports.registerHook = (hook_name, plugin, payload) ->
  keys = hook_name.split '.'
  last_key = keys.pop()

  pointer = exports.hooks

  for item in keys
    if pointer[item] == undefined
      pointer[item] = {}
      pointer = pointer[item]
    else
      pointer = pointer[item]

  pointer[last_key] ?= []
  pointer[last_key].push _.extend payload,
    plugin_info: plugin

exports.selectHook = (account, hook_name) ->
  keys = hook_name.split '.'

  pointer = exports.hooks

  for item in keys
    if pointer[item] == undefined
      throw new Error 'Invalid hook name'
    else
      pointer = pointer[item]

  return _.filter pointer, (hook) ->
    if hook.plugin_info.type == 'extension'
      return true
    else if hook.plugin_info.name in account.billing.services
      return true
    else
      return false

exports.initializePlugins = (callback) ->
  checkDependencies = ->
    all_plugins = _.union config.plugin.available_extensions, config.plugin.available_services

    for plugin_name in all_plugins
      plugin = require path.join __dirname, "../plugin/#{plugin_name}"

      if plugin.dependencies
        for dependence in plugin.dependencies
          unless dependence in all_plugins
            throw new Error "#{plugin_name} is Dependent on #{dependence} but not load"

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

  checkDependencies()

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

exports.createHelpers = (plugin) ->
  plugin.registerHook = (hook_name, payload) ->
    return exports.registerHook hook_name, plugin, payload

  return plugin
