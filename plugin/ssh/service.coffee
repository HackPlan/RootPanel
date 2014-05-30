child_process = require 'child_process'
jade = require 'jade'
path = require 'path'
async = require 'async'

plugin = require '../../core/plugin'

module.exports =
  enable: (account, callback) ->
    plugin.systemOperate (callback) ->
      child_process.exec "sudo useradd -m -s /bin/bash #{account.username}", (err, stdout, stderr) ->
        throw err if err
        callback()
    , callback

  delete: (account, callback) ->
    plugin.systemOperate (callback) ->
      async.series [
        (callback) ->
          child_process.exec "sudo pkill -u #{account.username}", ->
            callback()

        (callback) ->
          child_process.exec "sudo userdel -rf #{account.username}", ->
            callback()
      ], (err) ->
        throw err if err
        callback()
    , callback

  widget: (account, callback) ->
    jade.renderFile path.join(__dirname, 'view/widget.jade'), {}, (err, html) ->
      callback html

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
