_ = require 'lodash'

###
  Registry: Collection of simple extend point,
  You can access a global instance via root.hooks.
###
module.exports = class HookRegistry
  constructor: ->
    @hooks =
      account:
        # filter: (account) -> Promise
        before_register: []

  ###
    Public: Register a hook.

    * `path` {String} e.g. `account.before_register`
    * `options` {Object}

      * `plugin` {Plugin}
      * Other options, depend on specific hook.

  ###
  register: (path, options) ->
    @getHooks(path, array: true).push options

  ###
    Public: Apply hooks.

    * `path` {String}
    * `options` {Object}

      * `execute` {String} Execute specific path.
      * `pluck` {String} Pluck specific path.
      * `req` {Object} Passed as `@req` when execute.
      * `param` Passed as parameter when execute.

    Return {Array}.
  ###
  applyHooks: (path, {execute, pluck, req, payload} = {}) ->
    return _.compact @getHooks(path).map (hook) ->
      if execute
        return hook[execute].call
          req: req
          plugin: hook.plugin
        , payload

      else if pluck
        return hook[pluck]

      else
        return hook

  ###
    Public: Execute hooks.

    Parameter same as {HookRegistry::applyHooks}.

    Return {Promise}.
  ###
  executeHooks: ->
    Q.all @dispatch arguments...

  getHooks: (path, {array, object} = {}) ->
    words = path.split '.'
    last = words.pop()

    ref = @hooks

    for word in words
      ref[word] ?= {}
      ref = ref[word]

    if array
      ref[last] ?= []
    else if object
      ref[last] ?= {}

    return ref[last]
