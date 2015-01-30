harp = require 'harp'

{_, path, fs, jade} = app.libs
{config, logger, i18n, utils} = app
{available_plugins} = config.plugin

ComponentTemplate = require './ComponentTemplate'

pluggable = require '../pluggable'

module.exports = class Plugin
  info: null
  name: null
  config: null
  path: null

  constructor: (@info) ->
    @name = info.name
    @config = config.plugins[@name] ? {}
    @path = path.join __dirname, '../../plugin', @name

    if info.dependencies
      for dependence in plugin.dependencies
        unless dependence in available_plugins
          err = new Error "Plugin:#{@name} is dependent on Plugin:#{dependence} but not load"
          logger.fatal err
          throw err

    for name, payload of info.register_hooks ? {}
      if payload.register_if
        unless payload.register_if.apply @
          continue

      @registerHook name, payload

    if info.initialize
      info.initialize.apply @

    if info.started
      app.on 'app.started', ->
        info.started.apply @

    if fs.existsSync path.join(@path, 'locale')
      i18n.initPlugin @

    if fs.existsSync path.join(@path, 'static')
      app.express.use harp.mount "/plugin/#{@name}", path.join(@path, 'static')

  registerComponent: (info) ->
    template = new ComponentTemplate _.extend info,
      plugin: @

    for name, payload of info.register_hooks ? {}
      if payload.register_if
        unless payload.register_if.apply @
          continue

      @registerHook name, _.extend payload,
        component_template: template

    pluggable.components[info.name] = template

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

  triggerUsages: (account, trigger_name, volume, callback) ->
    trigger_name = utils.formatBillingTrigger trigger_name
    app.billing.acceptUsagesBilling account,trigger_name, volume, callback
