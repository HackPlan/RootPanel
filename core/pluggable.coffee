{async, path, harp, jade, tmp, fs, _, child_process} = app.libs
{i18n, config, logger} = app

Plugin = require './interface/Plugin'

pluggable = _.extend exports,
  plugins: {}

pluggable.hooks =
  app:
    # path: string
    ignore_csrf: []

  model:
    # model: string, field: string, type: string
    type_enum: []

    # model: string, action(schema, callback)
    middleware: []

  account:
    # filter: function(username, callback(is_allow))
    username_filter: []
    # filter: function(account, callback)
    before_register: []
    # filter: function(account, callback)
    resources_limit_changed: []

  billing:
    # type
    # widgetGenerator: function(req, callback(html)),
    # detailsMessage: function(req, deposit_log, callback(l_details))
    payment_methods: []

  view:
    layout:
      # href, target, body
      menu_bar: []
      # path
      scripts: []
      # path
      styles: []

    admin:
      # generator: function(req, callback)
      sidebars: []

    panel:
      # path
      scripts: []
      # generator: function(req, callback)
      widgets: []
      # path
      styles: []

pluggable.initPlugins = ->
  for name in config.plugin.available_plugins
    pluggable.plugins[name] = require path.join __dirname, '../plugin', name

pluggable.selectHookPath = (name) ->
  words = name.split '.'

  ref = pluggable.hooks

  for word in words
    ref[word] ?= {}
    ref = ref[word]

  return ref

pluggable.selectHooks = (name, options) ->
  return _.filter pluggable.selectHookPath(name), (hook) ->
    return !hook.component_meta

pluggable.selectComponentHooks = (name, account, callback) ->
