{config} = app

exports.nodes = {}

exports.Node = Node = class Node
  constructor: (@info) ->

exports.initializeNodes = ->
  for name, info of config.nodes
    exports[name] = new Node info
