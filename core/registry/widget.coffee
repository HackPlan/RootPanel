###
  Public: Add widgets to panel page.
  You can access a global instance via `root.widgets`.
###
module.exports = class WidgetRegistry
  constructor: ->
    @widgets = {}

  ###
    Public: Register a widget.

    * `view` {String} Currently only `panel`
    * `options` {Object}

      * `plugin` {Plugin}
      * `generator` {Function} Return {Promise} resolve with html
      * `repeating` (optional) {Object} Control how to repeating widget

        * `components` (optional) {Object} Component name as key, value are some of:

          * `createable` (optional) {Boolean} Required user can create component.
          * `having` (optional) {Boolean} Required user has at least one component.
          * `every` (optional) {Boolean} Repeating every component.
          * `every_node` (optional) {Boolean} Repeating every node of components.

    ## Example

    Always show a widget:

    ```coffee
    root.widgets.register 'panel',
      plugin: plugin
      generator: (account) ->
    ```

    Show a widget if user can create `ssh` component.

    ```coffee
    root.widgets.register 'panel',
      plugin: plugin
      generator: (account) ->
      repeating:
        components:
          ssh:
            createable: true
    ```

    Show a widget if user has `ssh` components.

    ```coffee
    root.widgets.register 'panel',
      plugin: plugin
      generator: (account, components) ->
      repeating:
        components:
          ssh:
            having: true
    ```

    Show a widget if user has both `pptp` and `shadowsocks`:

    ```coffee
    root.widgets.register 'panel',
      plugin: plugin
      generator: (account, {pptps, shadowsockses}) ->
      repeating:
        components:
          pptp:
            having: true
          shadowsocks:
            having: true
    ```

    Show widgets for every `ssh` component of user.

    ```coffee
    root.widgets.register 'panel',
      plugin: plugin
      generator: (account, component) ->
      repeating:
        components:
          ssh:
            every: true
    ```

    Show widgets for every node of `ssh` component of user.

    ```coffee
    root.widgets.register 'panel',
      plugin: plugin
      generator: (account, components) ->
      repeating:
        components:
          ssh:
            every_node: true
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
