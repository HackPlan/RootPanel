_ = require 'lodash'

###
  Public: Collection of simple extend point.
  You can access a global instance via root.hooks.
###
module.exports = class HookRegistry
  constructor: ->
    @hooks =
      middleware:
        ignore_csrf: []

      account:
        # filter: (account) ->
        before_register: []

  register: (path, options) ->
    @getHooks(path, array: true).push options

  getHooks: (path, options) ->
    words = path.split '.'
    last = words.pop()

    ref = @hooks

    for word in words
      ref[word] ?= {}
      ref = ref[word]

    if options?.array
      ref[last] ?= []
    else if options?.object
      ref[last] ?= {}

    return ref[last]

  applyHooks: (path, {execute, pluck, req, params} = {}) ->
    return _.compact @getHooks(path).map (hook) ->
      if execute
        return hook[execute].apply
          req: req
          plugin: hook.plugin
        , params...

      else if pluck
        return hook[pluck]

      else
        return hook

  executeHooks: ->
    Q.all @dispatch arguments...
