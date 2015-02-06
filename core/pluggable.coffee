{async, path, harp, jade, tmp, fs, _, child_process} = app.libs
{i18n, config, logger} = app
{Componnet} = app.models

Plugin = require './interface/Plugin'

pluggable = _.extend exports,
  plugins: {}
  components: {}

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

pluggable.applyHooks = (name, account, options = {}) ->
  {execute, req} = options

  result = []

  for hook in pluggable.selectHookPath(name)
    template = hook.component_template
    timing = hook.timing

    pushResult = (hook, payload = {}) ->
      if execute
        result.push (callback) ->
          params = []

          {account, node, components, component} = payload

          params.push account if account
          params.push node if node
          params.push components if components
          params.push component if component
          params.push callback

          hook[execute].apply
            req: req
            template: template
            plugin: hook.plugin
          , params

      else
        result.push _.extend {}, hook, payload

    if !template or timing == 'always'
      pushResult hook
      continue

    unless account
      continue

    if timing == 'available'
      if template in account.getAvailableComponentsTemplates()
        pushResult hook,
          account: account

      continue

    components = _.filter account.components, (component) ->
      return component.template == template.name

    if timing == 'once'
      unless _.isEmpty components
        pushResult hook,
          account: account
          components: components

      continue

    if timing == 'every'
      for component in components
        pushResult hook,
          account: account
          component: component

      continue

    if timing == 'every_node'
      components_by_node = _.groupBy components, (component) ->
        return component.node_name

      for node_name, components of components_by_node
        pushResult hook,
          account: account
          node: app.nodes[node_name]
          components: components

      continue

  if execute
    return (callback) ->
      async.series result, callback
  else
    return result
