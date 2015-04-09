class Plugin
  defaults:
    name: null
    dependencies: []
    initialize: ->
    started: ->

  constructor: (options) ->
    {name} = options

    if fs.existsSync path.join(@path, 'static')
      app.express.use harp.mount "/plugins/#{name}", path.join(@path, 'static')

    if fs.existsSync path.join(@path, 'locale')
      i18n.initPlugin @

    @initialize()

    rp.on 'app.started', =>
      @started()

  registerHook: (endpoint, options) ->
    app.extends.hook.register @, endpoint, options

  registerComponent: (options) ->
    app.extends.component.register @, options

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
    template_path = path.join __dirname, '../../plugins', @name, 'view', "#{name}.jade"

    locals = _.extend {}, req.res.locals, view_data,
      account: req.account
      t: @getTranslator req

    jade.renderFile template_path, locals, callback

  renderTemplate: (name, view_data, callback) ->
    template_path = path.join __dirname, '../../plugins', @name, 'view', name

    fs.readFile template_path, (err, template_file) ->
      callback _.template(template_file.toString()) view_data

  triggerUsages: (account, trigger_name, volume, callback) ->
    trigger_name = utils.formatBillingTrigger trigger_name
    app.billing.acceptUsagesBilling account,trigger_name, volume, callback

class Plugin

class Injector
  constructor: ({Plugin, name, path, config, extend}) ->
    @extend = extend
    @plugin = new Plugin @, config

    _.extend @plugin,
      name: name
      path: path

  plugin: ->
    return @plugin

  hook: (path, options) ->
    return @extend.hooks.register path _.extend options,
      plugin: @plugin

  component: (options) ->
    return @extend.components.register _.extend options,
      plugin: @plugin

  coupon: (options) ->
    return @extend.coupons.register _.extend options,
      plugin: @plugin

  payment: (options) ->
    return @extend.payments.register _.extend options,
      plugin: @plugin

module.exports = class PluginManager
  constructor: (@config) ->
    @plugins = {}

    for name, config of @config
      if config.enable
        @add name, config

  add: (name, config) ->
    if @plugins[name]
      throw new Error "plugin `#{name}` already exists"

    plugin_path = path.join __dirname, '../plugins', name

    injector = new Injector
      Plugin: require plugin_path
      name: name
      path: plugin_path
      config: config
      extend: rp.extends

    @plugins[name] = injector.plugin()

  all: ->
    return _.values @plugins

  byName: (name) ->
    return @plugins[name]
