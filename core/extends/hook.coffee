{_, async, Q} = app.libs

app.hooks =
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

exports.register = (owner, endpoint, options) ->
  if owner.isComponent
    _.extend options,
      plugin: owner.plugin
      component: owner
  else if owner.isPlugin
    _.extend options,
      plugin: owner
  else
    throw error 'must provide a plugin or component'

  exports.selectHookPath(endpoint, array: true).push options

exports.selectHookPath = (name, options) ->
  words = name.split '.'
  last = words.pop()

  ref = app.hooks

  for word in words
    ref[word] ?= {}
    ref = ref[word]

  if options?.array
    ref[last] ?= []
  else if options?.object
    ref[last] ?= {}

  return ref[last]

exports.getHooks = (name, account, {execute, pluck, req} = {}) ->
  return _.compact _.flatten exports.selectHookPath(name).map (hook) ->
    {component, timing} = hook

    result = (params) ->
      if execute
        return hook[execute].apply
          req: req
          component: component
          plugin: hook.plugin
        , params...

      else if pluck
        return _.extend({}, hook, params)[pluck]

      else
        return _.extend {}, hook, params

    if !component or timing == 'always'
      return result()

    unless account
      return

    if timing == 'available'
      if component in account.getAvailableComponentsTemplates()
        return result account

    components = _.filter account.components, (component) ->
      return component.template == template.name

    if timing == 'once'
      unless _.isEmpty components
        return result account, components

    if timing == 'every'
      return components.map (component) ->
        return result account, component

    if timing == 'every_node'
      return _.each _.groupBy(components, 'node_name'), (node_name, components) ->
        return result account, app.nodes[node_name], components

exports.applyHooks = ->
  return Q.all exports.getHooks arguments...

error = (message) ->
  err = new Error 'core.extends.hook: ' + message
  logger.fatal err
  return err
