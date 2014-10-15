async = require 'async'
path = require 'path'
harp = require 'harp'
jade = require 'jade'
fs = require 'fs'
_ = require 'underscore'

i18n = require './i18n'
config = require './../config'

exports.plugins = {}

hookHelper = (options) ->
  return _.extend [], options

exports.hooks =
  account:
    # filter: function(username, callback(is_allow))
    username_filter: hookHelper
      always_notice: true
    # filter: function(account, callback)
    before_register: hookHelper
      always_notice: true
    # action: function(account, callback)
    resources_limit_changed: []

  billing:
    # widget_generator: function(req, callback(html))
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
      # generator: function(req, callback)
      widgets: []
      # path
      styles: []
      # name
      switch_buttons: []

    pay:
      # type, filter: function(req, deposit_log, callback(l_details))
      display_payment_details: []

  service:
    'service_name':
      # action: function(req, callback)
      enable: []
      # action: function(req, callback)
      disable: []

  plugin:
    wiki:
      # t_category, t_title, language, content_markdown
      pages: []

exports.createHookPoint = (hook_name) ->
  keys = hook_name.split '.'

  pointer = exports.hooks

  for item in keys
    if pointer[item] == undefined
      pointer[item] = {}

    pointer = pointer[item]

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
    else if pointer.always_notice or hook.always_notice
      return true
    else if !account
      return false
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

  plugin.registerServiceHook = (hook_name, payload) ->
    return plugin.registerHook "service.#{plugin.name}.#{hook_name}", payload

  plugin.t = (req) ->
    return (name) ->
      full_name = "plugins.#{plugin.name}.#{name}"

      args = _.toArray arguments
      args[0] = full_name

      full_result = req.res.locals.t.apply @, args

      unless full_result == full_name
        return full_result

      return req.res.locals.t.apply @, _.toArray(arguments)

  plugin.render = (template_name, req, view_data, callback) ->
    template_path = path.join __dirname, "../plugin/#{plugin.name}/view/#{template_name}.jade"

    locals = _.extend _.clone(req.res.locals), view_data,
      account: req.account

      t: plugin.t req

    jade.renderFile template_path, locals, (err, html) ->
      throw err if err
      callback html

  return plugin
