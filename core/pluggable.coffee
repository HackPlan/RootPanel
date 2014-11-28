{async, path, harp, jade, tmp, fs, _, child_process} = app.libs
{i18n, config, logger} = app

pluggable = exports

pluggable.plugins = {}
pluggable.components = {}

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

    pay:
      # type, filter: function(req, deposit_log, callback(l_details))
      display_payment_details: []

Plugin = class Plugin
  info: null
  name: null
  config: null

  constructor: (@info) ->
    @name = @info.name
    @config = config.plugins[@name] ? {}

  registerComponent: (info) ->
    component_meta = new ComponentMeta _.extend info,
      plugin: @

    pluggable.components[info.name] = component_meta

  registerHook: (name, payload) ->
    words = name.split '.'
    last_word = words.pop()

    hook_path = pluggable.selectHookPath words.join('.')
    hook_path[last_word] ?= []

    hook_path[last_word].push _.extend payload,
      plugin: @

  getTranslator: (languages) ->
    return (name) =>
      if _.isArray languages
        t = i18n.getTranslator languages
      else
        t = i18n.getTranslatorByReq languages

      args = _.toArray arguments
      args[0] = "plugins.#{@name}.#{name}"

      full_result = t.apply @, args

      unless full_result == full_name
        return full_result

      return t.apply @, _.toArray(arguments)

  render: (name, req, view_data, callback) ->
    template_path = path.join __dirname, '../plugin', @name, 'view', "#{name}.jade"

    locals = _.extend _.clone(req.res.locals), view_data,
      account: req.account
      t: @getTranslator req

    jade.renderFile template_path, locals, (err, html) ->
      logger.error err if err
      callback html

  renderTemplate: (name, view_data, callback) ->
    template_path = path.join __dirname, '../plugin', @name, 'view', name

    fs.readFile template_path, (err, template_file) ->
      callback _.template(template_file.toString()) view_data

ComponentMeta = class ComponentMeta
  info: null
  name: null

  constructor: (@info) ->
    @name = @info.name

pluggable.selectHookPath = (name) ->
  words = name.split '.'

  hook_path = pluggable.hooks

  for word in words
    hook_path[word] ?= {}
    hook_path = hook_path[word]

  return path

pluggable.selectHook = (name) ->
  return pluggable.selectHookPath name

pluggable.initPlugin = (name) ->
  plugin_path = path.join __dirname, '../plugin', name
  plugin = require plugin_path

  for path, payload in plugin.register_hooks ? {}
    if payload.test and payload.test.apply @
      plugin.registerHook path, payload

  plugin.initialize()

  if fs.existsSync path.join(plugin_path, 'locale')
    i18n.initPlugin plugin, callback

  if fs.existsSync path.join(plugin_path, 'static')
    app.express.use harp.mount "/plugin/#{name}", path.join(plugin_path, 'static')

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

  for name in plugins_name
    pluggable.initPlugin name

_.extend app.classes,
  Plugin: Plguin
  ComponentMeta: ComponentMeta
