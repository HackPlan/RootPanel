jade = require 'jade'
path = require 'path'

module.exports =
  update_passwd:
    mode: 'passwd'
    callback: ->

  killall:
    mode: 'alert'
    callback: ->

  reset_permission:
    mode: 'alert'
    callback: ->

  widget: (callback) ->
    jade.renderFile path.join(__dirname, 'view/widget.jade'), {}, (err, html) ->
      callback html
