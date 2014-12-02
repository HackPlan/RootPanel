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

Plugin = class Plugin
  info: null
  name: null
  config: null
  path: null

  constructor: (@info) ->
    @name = info.name
    @config = config.plugins[@name] ? {}
    @path = path.join __dirname, '../plugin', @name

    for name, payload of info.register_hooks ? {}
      if payload.register_if
        unless payload.register_if.apply @
          continue

      @registerHook name, payload

    if info.initialize
      info.initialize.apply @

    if fs.existsSync path.join(@path, 'locale')
      i18n.initPlugin @

    if fs.existsSync path.join(@path, 'static')
      app.express.use harp.mount "/plugin/#{@name}", path.join(@path, 'static')

  registerComponent: (info) ->
    component_meta = new ComponentMeta _.extend info,
      plugin: @

    for path, payload of info.register_hooks ? {}
      if payload.register_if and payload.register_if.apply @
        @registerComponentHook path, _.extend payload,
          component_meta: component_meta

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

      full_name = "plugins.#{@name}.#{name}"

      args = _.toArray arguments
      args[0] = full_name

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

_.extend app.classes,
  Plugin: Plugin
  ComponentMeta: ComponentMeta
