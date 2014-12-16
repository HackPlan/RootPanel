{_, path, fs, jade, harp} = app.libs
{config, logger, i18n} = app
{available_plugins} = config.plugin

pluggable = require '../pluggable'

module.exports = class Plugin
  info: null
  name: null
  config: null
  path: null

  @plugins = {}

  @get: (name) ->
    return @plugins[name]

  @initPlugins: ->
    for name in available_plugins
      Plugin.plugins[name] = require path.join __dirname, '../../plugin', name

  constructor: (@info) ->
    @name = info.name
    @config = config.plugins[@name] ? {}
    @path = path.join __dirname, '../../plugin', @name

    if info.dependencies
      for dependence in plugin.dependencies
        unless dependence in available_plugins
          err = new Error "Plugin:#{@name} is Dependent on Plugin:#{dependence} but not load"
          logger.fatal err
          throw err

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

    for name, payload of info.register_hooks ? {}
      if payload.register_if
        unless payload.register_if.apply @
          continue

      @registerComponentHook name, _.extend payload,
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
    template_path = path.join __dirname, '../../plugin', @name, 'view', "#{name}.jade"

    locals = _.extend _.clone(req.res.locals), view_data,
      account: req.account
      t: @getTranslator req

    jade.renderFile template_path, locals, (err, html) ->
      logger.error err if err
      callback html

  renderTemplate: (name, view_data, callback) ->
    template_path = path.join __dirname, '../../plugin', @name, 'view', name

    fs.readFile template_path, (err, template_file) ->
      callback _.template(template_file.toString()) view_data
