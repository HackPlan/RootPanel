child_process = require 'child_process'
fs = require 'fs'

config = require '../../config.coffee'

last_plist = []
passwd_cache = {}

exports.run = ->
  setInterval exports.monitoring, config.plugins.linux.cycle

exports.loadPasswd = (callback) ->
  fs.readFile '/etc/passwd', (err, content) ->
    content = content.split '\n'

    passwd_cache = {}

    for line in content
      if line
        [username, , uid] = line.split ':'
        passwd_cache[uid] = username

    callback()

exports.monitoring = ->
  exports.loadPasswd ->
    child_process.exec "ps awufx", (err, stdout, stderr) ->
      plist = stdout.split('\n')[1...-1]

      plist = _.reject plist, (item) ->
        return item[..3] == 'root'

      plist = _.map plist, (item) ->
        rx = /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)$/
        result = rx.exec item
        return {
          user: result[1]
          pid: result[2]
          cpu_per: result[3]
          mem_per: result[4]
          vsz: result[5]
          rss: result[6]
          tty: result[7]
          stat: result[8]
          start: result[9]
          time: result[10]
          command: result[11]
        }

      async.parallel [
        (callback) ->
          exports.monitoringCpu plist, callback
      ]

      last_plist = plist

exports.monitoringCpu = (plist, callback) ->
  exist_process = _.filter plist, (item) ->
    return _.find last_plist, (i) ->
      return i.pid == item.pid and i.user == item.user and i.command == item.command

  new_process = _.fliter plist, (item) ->
    return not _.find last_plist, (i) ->
      return i.pid == item.pid and i.user == item.user and i.command == item.command
  

exports.monitoringMemory = (plist, callback) ->
