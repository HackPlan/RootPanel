_ = require 'lodash'
Q = require 'q'

Component = require '../model/component'

###
  Public: Add widgets to panel page.
  You can access a global instance via `root.widgets`.
###
module.exports = class WidgetRegistry
  constructor: ->
    @widgets = {}

  ###
    Public: Register a widget.

    * `view` {String} Currently only `panel`.
    * `options` {Object}

      * `plugin` {Plugin}
      * `generator` {Function} Return {Promise} resolve with html.
      * `required` (optional) {Object} Control how to show this widget, value is component type.

        * `createable` (optional) {String} or {Array} Required user can create component.
        * `having` (optional) {String} or {Array} Required user has at least one component.

      * `repeating` (optional) {Object} Control how to repeating this widget, value is component type.

        Implied `required.having`.

        * `every` (optional) {String} Repeating every component.
        * `every_node` (optional) {String} Repeating every node of components.

    ## Parameters passed to `generator`

    High-priority rule first.

      * `(account, components) ->` if have `repeating.every_node`.
      * `(account, component) ->` if have `repeating.every`.
      * `(account, {type1: components, type2: components}) ->` if have multiple `required.having`.
      * `(account, components) ->` if have single `required.having`.
      * `(account) ->` Default rule.

    ## Example

    Always show a widget:

    ```coffee
    root.widgets.register 'panel',
      generator: (account) ->
    ```

    Show a widget if user can create `ssh` component.

    ```coffee
    root.widgets.register 'panel',
      generator: (account) ->
      required:
        createable: 'ssh'
    ```

    Show a widget if user has `ssh` components.

    ```coffee
    root.widgets.register 'panel',
      generator: (account, components) ->
      required:
        having: 'ssh'
    ```

    Show a widget if user has both `pptp` and `shadowsocks`:

    ```coffee
    root.widgets.register 'panel',
      generator: (account, {pptps, shadowsockses}) ->
      required:
        having: ['pptp', 'shadowsocks']
    ```

    Show widgets for every `ssh` component of user.

    ```coffee
    root.widgets.register 'panel',
      generator: (account, component) ->
      repeating:
        every: 'ssh'
    ```

    Show widgets for every node of `ssh` component of user.

    ```coffee
    root.widgets.register 'panel',
      generator: (account, components) ->
      repeating:
        every_node: 'ssh'
    ```

  ###
  register: (view, options) ->
    @widgets[view] ?= []
    @widgets[view].push options

  ###
    Public: Dispatch.

    * `view` {String}
    * `account` {Account}

    Return {Promise} resolve with {Array} of html.
  ###
  dispatch: (view, account) ->
    required_createable = new Error 'required createable'
    required_having = new Error 'required having'

    asArray = (value) ->
      if value in [null, undefined]
        return []
      if _.isArray value
        return value
      else
        return [value]

    Component.getComponents(account).then (components) =>
      Q.all (@widgets[view] ? []).map (widget) ->
        {required, repeating, generator} = widget

        Q().then ->
          for type in asArray(required?.createable)
            unless type in root.billing.availableComponents(account)
              throw required_createable

          for type in asArray(required?.having)
            unless _.findWhere(components, type: type)
              throw required_having

        .then ->
          if repeating?.every_node
            Q.all _(components).where(type: repeating.every_node).groupBy('node').values().value().map (components) ->
              generator account, components

          else if repeating?.every
            Q.all _(components).where(type: repeating.every_node).map (component) ->
              generator account, component

          else if required?.having?.length > 1
            generator account, _.zipObject asArray(required.having), asArray(required.having).map (type) ->
              return _.where components, type: type

          else if required?.having
            generator account, _.where type: asArray(required.having)[0]

          else
            generator account

        .catch (err) ->
          unless err in [required_createable, required_having]
            throw err

      .then (result) ->
        return _.compact result
