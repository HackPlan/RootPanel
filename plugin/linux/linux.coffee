child_process = require 'child_process'
os = require 'os'
fs = require 'fs'
async = require 'async'
_ = require 'underscore'

{cache} = app
{wrapAsync} = app.utils

monitor = require './monitor'

exports.createUser = (account, callback) ->
  async.series [
    (callback) ->
      child_process.exec "sudo useradd -m -s /bin/bash #{account.username}", callback

    (callback) ->
      child_process.exec "sudo usermod -G #{account.username} -a www-data", callback

  ], (err) ->
    console.error err if err
    cache.delete 'linux.getPasswdMap', ->
      callback()

exports.deleteUser = (account, callback) ->
  async.series [
    (callback) ->
      child_process.exec "sudo pkill -u #{account.username}", ->
        callback()

    (callback) ->
      child_process.exec "sudo userdel -rf #{account.username}", callback

    (callback) ->
      child_process.exec "sudo groupdel #{account.username}", callback

  ], (err) ->
    console.error err if err
    cache.delete 'linux.getPasswdMap', ->
      callback()

exports.setResourceLimit = (account, callback) ->
  unless 'linux' in account.billing.services
    return callback()

  storage_limit = account.resources_limit.storage
  soft_limit = (storage_limit * 1024 * 0.8).toFixed()
  hard_limit = (storage_limit * 1024 * 1.2).toFixed()
  soft_inode_limit = (storage_limit * 64 * 0.8).toFixed()
  hard_inode_limit = (storage_limit * 64 * 1.2).toFixed()

  child_process.exec "sudo setquota -u #{account.username} #{soft_limit} #{hard_limit} #{soft_inode_limit} #{hard_inode_limit} -a", (err) ->
    console.error err if err
    callback()

exports.getPasswdMap = (callback) ->
  cache.try 'linux.getPasswdMap',
    command: cache.SETEX 120
    is_json: true
  , (callback) ->
    fs.readFile '/etc/passwd', (err, content) ->
      console.error err if err
      result = {}

      for line in _.compact(content.toString().split '\n')
        [username, password, uid] = line.split ':'
        result[uid] = username

      callback result
  , callback

exports.getMemoryInfo = (callback) ->
  cache.try 'linux.getProcessList',
    command: cache.SETEX 3
    is_json: true
  , (callback) ->
    fs.readFile '/proc/meminfo', (err, content) ->
      console.error err if err
      mapping = {}

      for line in content.toString().split('\n')
        [key, value] = line.split ':'
        if value
          mapping[key.trim()] = parseInt (parseInt(value.trim().match(/\d+/)) / 1024).toFixed()

      used = mapping['MemTotal'] - mapping['MemFree'] - mapping['Buffers'] - mapping['Cached']
      used_per = (used / mapping['MemTotal'] * 100).toFixed()
      cached_per = (mapping['Cached'] / mapping['MemTotal'] * 100).toFixed()
      buffers_per = (mapping['Buffers'] / mapping['MemTotal'] * 100).toFixed()
      free_per = 100 - used_per - cached_per - buffers_per

      swap_free_per = (mapping['SwapFree'] / mapping['SwapTotal'] * 100).toFixed()
      swap_used_per = 100 - swap_free_per

      callback
        used: used
        cached: mapping['Cached']
        buffers: mapping['Buffers']
        free: mapping['MemFree']
        total: mapping['MemTotal']
        swap_used: mapping['SwapTotal'] - mapping['SwapFree']
        swap_free: mapping['SwapFree']
        swap_total: mapping['SwapTotal']

        used_per: used_per
        cached_per: cached_per
        buffers_per: buffers_per
        free_per: free_per

        swap_used_per: swap_used_per
        swap_free_per: swap_free_per

  , callback

exports.getProcessList = (callback) ->
  cache.try 'linux.getProcessList',
    command: cache.SETEX 5
    is_json: true
  , (callback) ->
    exports.getPasswdMap (passwd_map) ->
      child_process.exec "sudo ps awufxn", (err, stdout) ->
        console.error err if err

        callback _.map stdout.split('\n')[1 ... -1], (item) ->
          result = /^\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)$/.exec item

          return {
            user: do ->
              if passwd_map[result[1]]
                return passwd_map[result[1]]
              else
                return result[1]

            time: do ->
              [minute, second] = result[10].split ':'
              return parseInt(minute) * 60 + parseInt(second)

            pid: parseInt result[2]
            cpu_per: parseInt result[3]
            mem_per: parseInt result[4]
            vsz: parseInt result[5]
            rss: parseInt result[6]
            tty: result[7]
            stat: result[8]
            start: result[9]
            command: result[11]
          }

  , callback

exports.getStorageQuota = (callback) ->
  cache.try 'linux.getStorageQuota',
    command: cache.SETEX 60
    is_json: true
  , (callback) ->
    child_process.exec "sudo repquota -a", (err, stdout) ->
      console.error err if err
      lines = _.filter stdout.split('\n')[5...-1], (i) -> i

      lines = _.map lines, (line) ->
        fields = _.filter line.split(' '), (i) -> i and i != ' '
        [username, __, size_used, size_soft, size_hard, inode_used, inode_soft, inode_hard, inode_grace] = fields

        if /days/.test inode_used
          [size_grace, inode_used, inode_soft, inode_hard, inode_grace] = [inode_used, inode_soft, inode_hard, inode_grace]

        return {
          username: username
          size_used: parseFloat (parseInt(size_used) / 1024 / 1024).toFixed(1)
          inode_used: parseInt inode_used
        }

      callback _.indexBy lines, 'username'

  , callback

exports.getSystemInfo = (callback) ->
  cache.try 'linux.getSystemInfo',
    command: cache.SETEX 30
    is_json: true
  , (callback) ->
    async.parallel
      system: (callback) ->
        fs.readFile '/etc/issue', (err, content) ->
          callback err, content.toString().replace(/\\\w/g, '').trim()

      address: (callback) ->
        result = []

        for name, info of os.networkInterfaces()
          for item in info
            unless item.internal
              result.push item.address

        callback result

    , (err, result) ->
      console.error err if err

      callback _.extend result,
        hostname: os.hostname()
        cpu: os.cpus()[0]['model']
        uptime: os.uptime()
        loadavg: _.map os.loadavg(), (i) -> parseFloat(i.toFixed(2))
        time: new Date()

  , callback

exports.getStorageInfo = (callback) ->
  cache.try 'linux.getStorageInfo',
    command: cache.SETEX 30
    is_json: true
  , (callback) ->
    child_process.exec "df -h", (err, stdout) ->
      console.error err if err
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

      callback
        used: used
        free: free
        total: total

        used_per: used_per
        free_per: free_per

  , callback

exports.getResourceUsageByAccounts = (callback) ->
  cache.try 'linux.getStorageInfo',
    command: cache.SETEX 20
    is_json: true
  , (callback) ->
    console.log 'getResourceUsageByAccounts'
    async.parallel
      storage_quota: wrapAsync exports.getStorageQuota
      process_list: wrapAsync exports.getProcessList

    , (err, result) ->
        console.error err if err
      resources_usage_by_accounts = []

      for username, usage of monitor.resources_usage
        resources_usage_by_accounts.push
          username: username
          cpu: usage.cpu
          memory: usage.memory
          storage: result.storage_quota[username]?.size_used ? 0
          process: _.filter(result.process_list, (i) -> i.user == username).length

      callback resources_usage_by_accounts

  , callback

exports.getResourceUsageByAccount = (account, callback) ->
  exports.getResourceUsageByAccounts (resources_usage_by_accounts) ->
    callback _.findWhere resources_usage_by_accounts,
      username: account.username
