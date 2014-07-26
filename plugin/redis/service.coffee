child_process = require 'child_process'
jade = require 'jade'
path = require 'path'
tmp = require 'tmp'
fs = require 'fs'

plugin = require '../../core/plugin'
monitor = require '../linux/monitor'

mAccount = require '../../core/model/account'

module.exports =
  enable: (account, callback) ->
    callback()

  delete: (account, callback) ->
    callback()

  switch: (account, is_enable, callback) ->
    if is_enable
      app.redis.del 'rp:process_list', =>
        @switch_status account, (is_act_enable) ->
          if is_act_enable
            return callback()

          child_process.exec plugin.sudoSu(account, 'redis-server --unixsocket ~/redis.sock --port 0 --daemonize yes'), (err) ->
            throw err if err
            app.redis.del 'rp:process_list', ->
              callback()
    else
      child_process.exec plugin.sudoSu(account, "pkill -ef -u #{account.username} redis-server"), ->
        callback()

  switch_status: (account, callback) ->
    monitor.getProcessList (plist) ->
      process = _.find plist, (i) ->
        return i.user == account.username and i.command.trim() == 'redis-server *:0'

      callback if process then true else false

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
