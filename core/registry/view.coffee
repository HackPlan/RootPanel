async = require 'async-q'
jade = require 'jade'
fs = require 'q-io/fs'
os = require 'os'
Q = require 'q'

###
  Public: Use jade syntax to inject html to web views.
  You can access a global instance via `root.views`.
###
module.exports = class ViewRegistry
  constructor: ->
    @viewExtends = {}
    @viewCache = {}

  ###
    Public: Register extends of view

    * `view` {String}
    * `options` {Object}

      * `plugin` {Plugin}
      * `source` {String} Jade code to extend view
      * `filename` {String} Jade code from file
      * `locals` {Object}

  ###
  register: (view, options) ->
    @viewExtends[view] ?= []

    if options.source
      @viewExtends[view].push options
    else
      fs.read(root.resolve options.filename).done (source) =>
        @viewExtends[view].push _.extend options,
          source: source

  ###
    Public: Flush view cache
  ###
  flushCache: ->
    @viewCache = {}

  ###
    Public: Render View

    * `view` {String}
    * `locals` {Object}

    return {Promise} resolve with html.
  ###
  render: (view, locals) ->
    Q.then =>
      if @viewCache[view]
        return @viewCache[view]
      else
        @resolve(view).tap (renderer) =>
          @viewCache[view] = renderer
    .then (renderer) ->
      locals = _.extend {}, _.pluck(@viewExtends[view], 'locals')..., locals
      return renderer locals

  ###
    Private: Resolve renderer.

    * `view` {String}

    return {Promise} resolve with {Function} `(locals) -> String`.
  ###
  resolve: (view) ->
    unless view[-5 ..] == '.jade'
      view += '.jade'

    extendSource = (source) =>
      return [source, _.pluck(@viewExtends[view], 'source')...].join os.EOL

    async.detect([
      view
      root.resolve view
      root.resolve 'view', view
      root.resolve '..', view
    ], fs.exists).then (filename) ->
      fs.read(filename).then (source) ->
        return jade.compile extendSource(source.toString()),
          filename: filename
