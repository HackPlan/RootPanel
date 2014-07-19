child_process = require 'child_process'
jade = require 'jade'
path = require 'path'
tmp = require 'tmp'
fs = require 'fs'

plugin = require '../../core/plugin'
monitor = require '../linux/monitor'

mAccount = require '../../core/model/account'

MEMCACHED_FLAGS = '-d -m 16'

module.exports =
  enable: (account, callback) ->
    mAccount.update _id: account._id,
      $set:
        'attribute.plugin.memcached.is_enable': false
    , ->
      callback()

  delete: (account, callback) ->
    callback()

  switch: (account, is_enable, callback) ->
    if is_enable
      app.redis.del 'rp:process_list', =>
        @switch_status account, (is_act_enable) ->
          if is_act_enable
            return callback()

          child_process.exec plugin.sudoSu(account, "memcached #{MEMCACHED_FLAGS} -s ~/memcached.sock"), ->
            callback()
    else
      child_process.exec plugin.sudoSu(account, "pkill -exf -u #{account.username} \"memcached #{MEMCACHED_FLAGS} -s /home/#{account.username}/memcached.sock\""), ->
        callback()

  switch_status: (account, callback) ->
    monitor.getProcessList (plist) ->
      process = _.find plist, (i) ->
        return i.user == account.username and i.command == "memcached #{MEMCACHED_FLAGS} -s /home/#{account.username}/memcached.sock"

      callback if process then true else false

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
