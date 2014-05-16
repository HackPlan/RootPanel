child_process = require 'child_process'
jade = require 'jade'
path = require 'path'

module.exports =
  enable: (account, callback) ->
    child_process.exec "sudo useradd -m -s /bin/bash #{account.username}", (err, stdout, stderr) ->
      throw err if err
      callback()

  pause: (account, callback) ->

  delete: (account, callback) ->
    child_process.exec "sudo userdel -rf #{account.username}", (err, stdout, stderr) ->
      throw err if err
      callback()

  widget: (callback) ->
    jade.renderFile path.join(__dirname, 'view/widget.jade'), {}, (err, html) ->
      callback html
