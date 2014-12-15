{async, path, harp, jade, tmp, fs, _, child_process} = app.libs
{i18n, config, logger} = app

pluggable = exports

pluggable.hooks =
  app:
    # action: function
    started: []

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
    # widget_generator: function(req, callback(html)),
    # details_message: function(req, deposit_log, callback(l_details))
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

pluggable.selectHookPath = (name) ->
  words = name.split '.'

  hook_path = pluggable.hooks

  for word in words
    hook_path[word] ?= {}
    hook_path = hook_path[word]

  return hook_path

pluggable.selectHook = (name) ->
  return pluggable.selectHookPath name

pluggable.initPlugins = ->
  plugins_name = config.plugin.available_plugins

  for name in plugins_name
    plugin = require path.join __dirname, '../plugin', name

    if plugin.dependencies
      for dependence in plugin.dependencies
        unless dependence in plugins_name
          err = new Error "#{name} is Dependent on #{dependence} but not load"
          logger.fatal err
          throw err

    exports.plugins[name] = plugin
