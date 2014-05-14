child_process = require 'child_process'

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
