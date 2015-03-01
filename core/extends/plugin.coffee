harp = require 'harp'

{config, logger, i18n} = app
{_, fs, path, jade} = app.libs

app.plugins ?= {}

class Plugin
  isPlugin: true

  constructor: (options) ->
    {name} = options

    _.extend @, options,
      config: config.plugins[name] ? {}
      path: path.join __dirname, '../../plugins', name

    if fs.existsSync path.join(@path, 'static')
      app.express.use harp.mount "/plugins/#{name}", path.join(@path, 'static')

    if fs.existsSync path.join(@path, 'locale')
      i18n.initPlugin @

    if @initialize
      @initialize()

    if @started
      app.on 'app.started', =>
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

# options: name, dependencies, initialize, started
exports.register = (options) ->
  {name, dependencies} = options

  unless name
    throw error 'plugin should have a name'

  if app.plugins[name]
    throw error "plugin `#{name}` already exists"

  if dependencies
    app.on 'app.modules_loaded', ->
      for dependence in dependencies
        unless dependence in _.keys app.plugins
          throw error "`#{name}` is dependent on `#{dependence}` but not load"

  app.plugins[name] = new Plugin options

error = (message) ->
  err = new Error 'core.extends.plugin: ' + message
  logger.fatal err
  return err
