jade = require 'jade'
path = require 'path'
monitor = require './monitor'

module.exports =
  enable: (account, callback) ->
    callback()

  delete: (account, callback) ->
    callback()

  widget: (account, callback) ->
    jade.renderFile path.join(__dirname, 'view/widget.jade'),
      account: account
      resources_usage: monitor.resources_usage[account.username] ? {cpu: 0, memory: 0}
    , (err, html) ->
      throw err if err
      callback html

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
