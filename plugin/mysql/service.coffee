jade = require 'jade'
path = require 'path'
async = require 'async'

module.exports =
  enable: (account, callback) ->
    callback()

  delete: (account, callback) ->
    callback()

  widget: (callback) ->
    jade.renderFile path.join(__dirname, 'view/widget.jade'), {}, (err, html) ->
      callback html

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
