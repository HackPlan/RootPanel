_ = require 'lodash'
Q = require 'q'

###
  Registry: Collection of simple extend point,
  You can access a global instance via root.hooks.
###
module.exports = class HookRegistry
  constructor: ->
    @hooks =
      account:
        # action: (account) -> Promise
        before_register: []
        # action: (account) -> Promise
        after_register: []

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
  applyHooks: (path, {execute, pluck, req, params} = {}) ->
    return _.compact @getHooks(path).map (hook) ->
      if execute
        return hook[execute].apply
          req: req
          plugin: hook.plugin
        , params

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
    Q.all @applyHooks arguments...

  getHooks: (path, {array, object} = {}) ->
    unless path
      return @hooks

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

  getHooksAsArray: (path) ->
    if path
      currentPaths = path.split '.'
    else
      currentPaths = []

    result = []

    iterator = (hooks) ->
      for k, v of hooks
        if _.isArray v
          for hook in v
            result.push _.extend {}, hook,
              path: [currentPaths..., k].join '.'
        else if _.isObject v
          currentPaths.push k
          iterator v
          currentPaths.pop()

    iterator @getHooks path

    return result
