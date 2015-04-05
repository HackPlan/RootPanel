async = require 'async-q'
jade = require 'jade'
fs = require 'q-io/fs'
os = require 'os'
Q = require 'q'

###
  Public: View registry
###
class ViewRegistry
  constructor: ->
    @view_extends = {}
    @view_cache = {}

  ###
    Public: Register extends of view

    * `view` {String}
    * `options` {Object}

      * `plugin` {Plugin}
      * `source` {String} Jade code to extend view

  ###
  register: (view, options) ->
    @view_extends[view] ?= []
    @view_extends[view].push options

  ###
    Public: Flush view cache
  ###
  flushCache: ->
    @view_cache = {}

  ###
    Public: Render View

    * `view` {String}
    * `locals` {Object}

    return {Promise} resolve with html.
  ###
  render: (view, locals) ->
    Q.then =>
      if @view_cache[view]
        return @view_cache[view]
      else
        @resolve(view).tap (render) =>
          @view_cache[view] = render
    .then (render) ->
      return render locals

  # return {Promise} resolve with render of `view`.
  resolve: (view) ->
    extendSource = (source) =>
      return [source, _.pluck(@view_extends[view], 'source')...].join os.EOL

    async.detect([
      view
      rp.resolve view
      rp.resolve 'core', view
      rp.resolve 'core/view', view
    ], fs.exists).then (filename) ->
      fs.read(filename).then (source) ->
        return jade.compile extendSource(source),
          filename: filename
