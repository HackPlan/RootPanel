child_process = require 'child_process'
jade = require 'jade'
path = require 'path'

plugin = require '../../core/pluggable'
monitor = require '../linux/monitor'

module.exports =
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
