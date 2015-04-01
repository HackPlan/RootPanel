_ = require 'underscore'

class Node
  defaults:
    name: null
    master: false

  constructor: (options) ->
    _.extend @, @defaults, options

module.exports = class NodeManager
  constructor: (nodes_config) ->
    @nodes = {}

    for name, options of nodes_config
      @nodes[name] = new Node _.extend options,
        name: name

  all: ->
    return _.values @nodes

  byName: (name) ->
    return @nodes[name]
