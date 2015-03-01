{_, async} = app.libs

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

exports.applyHooks = (name, account, options = {}) ->
  {execute, pluck, req} = options

  result = []

  for hook in exports.selectHookPath(name)
    template = hook.component
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

      else if pluck
        result.push _.extend({}, hook, payload)[pluck]

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

error = (message) ->
  err = new Error 'core.extends.hook: ' + message
  logger.fatal err
  return err
