child_process = require 'child_process'

config = require '../../config.coffee'

last_plist = {}

account_cache = []

account_cache_sample = [
  username: 'jysperm'
]

exports.run = ->
  setInterval exports.monitoring, config.plugins.linux.cycle

exports.monitoring = ->
  child_process.exec "ps awufx", (err, stdout, stderr) ->
    plist = stdout.split('\n')[1...-1]

    plist = _.filter plist, (item) ->
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

    last_plist = plist
