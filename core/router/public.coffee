child_process = require 'child_process'
os = require 'os'
fs = require 'fs'

plugin = require '../plugin'
{renderAccount, requireAuthenticate} = require './middleware'

monitor = require '../../plugin/linux/monitor'

module.exports = exports = express.Router()

exports.get '/monitor', renderAccount, requireAuthenticate, (req, res) ->
  async.parallel
    resources_usage: (callback) ->
      monitor.monitoringStorage ->
        resources_usage = []

        for username, usage of monitor.resources_usage
          resources_usage.push
            username: username
            cpu: usage.cpu
            memory: usage.memory
            storage: parseInt monitor.storage_usage[username]?.size_used ? 0
            process: _.filter(monitor.last_plist, (i) -> i.user == username).length

        callback null, resources_usage

    system: (callback) ->
      async.parallel
        system: (callback) ->
          fs.readFile '/etc/issue', (err, content) ->
            callback err, content.toString().replace(/\\\w/g, '').trim()

      , (err, result) ->
        callback null, _.extend result,
          hostname: os.hostname()
          cpu: os.cpus()[0]['model']
          uptime: os.uptime()
          loadavg: _.map(os.loadavg(), (i) -> i.toFixed(2)).join(', ')
          address: os.networkInterfaces()['eth0'][0].address
          time: new Date()

    storage: (callback) ->
      child_process.exec "df -h", (err, stdout) ->
        disks = {}

        for line in stdout.split('\n')
          [dev, size, used, available, used_per, mounted] = _.compact(line.split(' '))

          disks[mounted] =
            dev: dev
            size: parseInt size?.match(/\d+/)
            used: parseInt used?.match(/\d+/)
            available: available
            used_per: used_per

        root_disk = disks['/']

        used = root_disk.used
        total = root_disk.size
        free = total - used

        used_per = (used / total * 100).toFixed()
        free_per = 100 - used_per

        callback null,
          used: used
          free: free
          total: total

          used_per: used_per
          free_per: free_per

    memory: monitor.loadMemoryInfo

  , (err, result) ->
    res.render 'public/monitor', _.extend result,
      last_plist: monitor.last_plist
      _: _
