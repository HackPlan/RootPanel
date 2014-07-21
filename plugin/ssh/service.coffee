child_process = require 'child_process'
jade = require 'jade'
path = require 'path'

plugin = require '../../core/plugin'
monitor = require '../linux/monitor'

module.exports =
  enable: (account, callback) ->
    child_process.exec "sudo useradd -m -s /bin/bash #{account.username}", (err, stdout, stderr) ->
      child_process.exec "sudo usermod -G #{account.username} -a www-data", (err, stdout, stderr) ->
        callback()

  delete: (account, callback) ->
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

  widget: (account, callback) ->
    monitor.getProcessList (plist) ->
      plist = _.filter plist, (i) ->
        return i.user == account.username

      for item in plist
        item.command = (/^[^A-Za-z0.9//]*(.*)/.exec(item.command))[1]

      jade.renderFile path.join(__dirname, 'view/widget.jade'),
        plist: plist
      , (err, html) ->
        callback html

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
