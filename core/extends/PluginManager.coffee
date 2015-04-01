harp = require 'harp'

{config, logger, i18n} = app
{_, fs, path, jade} = app.libs

class Plugin
  isPlugin: true

  defaults:
    name: null
    dependencies: []
    initialize: ->
    started: ->

  constructor: (options) ->
    {name} = options

    _.extend @, @defaults, options,
      config: config.plugins[name] ? {}
      path: path.join __dirname, '../../plugins', name

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

module.exports = class PluginManager
  constructor: ->
    @plugins = {}

  register: (options) ->
    {name, dependencies} = options

    unless name
      throw new Error 'plugin should have a name'

    if @plugins[name]
      throw new Error "plugin `#{name}` already exists"

    if dependencies
      app.on 'app.modules_loaded', ->
        for dependence in dependencies
          unless dependence in _.keys @plugins
            throw new Error "`#{name}` is dependent on `#{dependence}` but not load"

    @plugins[name] = new Plugin options

  all: ->
    return _.values @plugins

  byName: (name) ->
    return @plugins[name]
