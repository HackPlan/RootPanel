{async, path, harp, jade, tmp, fs, _, child_process} = app.libs
{i18n, config, logger} = app

exports.plugins = {}

exports.hooks =
  app:
    # action: function
    started: _.extend [],
      global_event: true

  model:
    # model: string, field: string, type: string
    type_enum: _.extend [],
      global_event: true

    # model: string, action(schema, callback)
    middleware: _.extend [],
      global_event: true

  account:
    # filter: function(username, callback(is_allow))
    username_filter: _.extend [],
      global_event: true
    # filter: function(account, callback)
    before_register: _.extend [],
      global_event: true
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
      # filter: function(req, callback)
      enable: []
      # filter: function(req, callback)
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
    else if pointer.global_event or hook.always_notice
      return true
    else if !account
      return false
    else if hook.plugin_info.name in account.billing.services
      return true
    else
      return false

exports.initializePlugins = ->
  plugins = _.union config.plugin.available_extensions, config.plugin.available_services

  for name in plugins
    plugin = require "#{__dirname}/../plugin/#{name}"

    if plugin.dependencies
      for dependence in plugin.dependencies
        unless dependence in plugins
          throw new Error "#{name} is Dependent on #{dependence} but not load"

    exports.plugins[name] = plugin

  for name, plugin in exports.plugins
    plugin_path = "#{__dirname}/../plugin/#{name}"

    if fs.existsSync path.join(plugin_path, 'locale')
      i18n.loadForPlugin plugin

    if fs.existsSync path.join(plugin_path, 'static')
      app.express.use harp.mount("/plugin/#{name}", path.join(plugin_path, 'static'))

exports.Plugin = class Plugin
  @registerHook: (hook_name, payload) ->
    return exports.registerHook hook_name, @, payload

  @registerServiceHook: (hook_name, payload) ->
    return @registerHook "service.#{@NAME}.#{hook_name}", payload

  @t: (req) ->
    return (name) =>
      full_name = "plugins.#{@NAME}.#{name}"

      args = _.toArray arguments
      args[0] = full_name

      full_result = req.res.locals.t.apply @, args

      unless full_result == full_name
        return full_result

      return req.res.locals.t.apply @, _.toArray(arguments)

  @render: (template_name, req, view_data, callback) ->
    template_path = "#{__dirname}/../plugin/#{@NAME}/view/#{template_name}.jade"

    locals = _.extend _.clone(req.res.locals), view_data,
      account: req.account
      t: @t req

    jade.renderFile template_path, locals, (err, html) ->
      logger.error err if err
      callback html

  @renderTemplate: (name, view_data, callback) ->
    template_path = "#{__dirname}/../plugin/#{@NAME}/template/#{name}"

    fs.readFile template_path, (err, template_file) ->
      callback _.template(template_file.toString()) view_data

  @writeConfigFile: (filename, content, callback) ->
    tmp.file
      mode: 0o750
    , (err, filepath, fd) ->
      logger.error err if err

      fs.writeSync fd, content, 0, 'utf8'
      fs.closeSync fd

      child_process.exec "sudo cp #{filepath} #{filename}", (err) ->
        logger.error err if err

        fs.unlink filepath, ->
          callback()
