{child_process, os, fs, async, _} = app.libs
{cache, logger} = app
{wrapAsync} = app.utils

monitor = require './monitor'

exports.createUser = (account, callback) ->
  async.series [
    (callback) ->
      child_process.exec "sudo useradd -m -s /bin/bash #{account.username}", callback

    (callback) ->
      child_process.exec "sudo usermod -G #{account.username} -a www-data", callback

  ], (err) ->
    logger.error err if err
    cache.delete 'linux.getPasswdMap', callback

exports.deleteUser = (account, callback) ->
  async.series [
    (callback) ->
      child_process.exec "sudo pkill -u #{account.username}", ->
        callback()

    (callback) ->
      child_process.exec "sudo userdel -rf #{account.username}", ->
        callback()

    (callback) ->
      child_process.exec "sudo groupdel #{account.username}", callback

  ], (err) ->
    logger.error err if err
    cache.delete 'linux.getPasswdMap', callback

exports.setResourceLimit = (account, callback) ->
  unless 'linux' in account.billing.services
    return callback()

  storage_limit = account.resources_limit.storage
  soft_limit = (storage_limit * 1024 * 0.8).toFixed()
  hard_limit = (storage_limit * 1024 * 1.2).toFixed()
  soft_inode_limit = (storage_limit * 64 * 0.8).toFixed()
  hard_inode_limit = (storage_limit * 64 * 1.2).toFixed()

  child_process.exec "sudo setquota -u #{account.username} #{soft_limit} #{hard_limit} #{soft_inode_limit} #{hard_inode_limit} -a", (err) ->
    logger.error err if err
    cache.delete 'linux.getStorageQuota', callback

exports.getPasswdMap = (callback) ->
  cache.try 'linux.getPasswdMap', (SETEX) ->
    fs.readFile '/etc/passwd', (err, content) ->
      logger.error err if err
      result = {}

      for line in _.compact(content.toString().split '\n')
        [username, password, uid] = line.split ':'
        result[uid] = username

      SETEX result, 120
  , callback

exports.getMemoryInfo = (callback) ->
  cache.try 'linux.getMemoryInfo', (SETEX) ->
    fs.readFile '/proc/meminfo', (err, content) ->
      logger.error err if err
      mapping = {}

      for line in content.toString().split('\n')
        [key, value] = line.split ':'
        if value
          mapping[key.trim()] = parseInt (parseInt(value.trim().match(/\d+/)) / 1024).toFixed()

      used = mapping['MemTotal'] - mapping['MemFree'] - mapping['Buffers'] - mapping['Cached']
      used_per = parseInt (used / mapping['MemTotal'] * 100).toFixed()
      cached_per = parseInt (mapping['Cached'] / mapping['MemTotal'] * 100).toFixed()
      buffers_per = parseInt (mapping['Buffers'] / mapping['MemTotal'] * 100).toFixed()
      free_per = 100 - used_per - cached_per - buffers_per

      swap_free_per = parseInt (mapping['SwapFree'] / mapping['SwapTotal'] * 100).toFixed()
      swap_free_per = 100 if _.isNaN swap_free_per
      swap_used_per = 100 - swap_free_per

      SETEX
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

        swap_used_per: swap_used_per ? 0
        swap_free_per: swap_free_per ? 0
      , 3

  , callback

exports.getProcessList = (callback) ->
  cache.try 'linux.getProcessList', (SETEX) ->
    exports.getPasswdMap (passwd_map) ->
      child_process.exec "sudo ps awufxn", (err, stdout) ->
        logger.error err if err

        plist = _.map stdout.split('\n')[1 ... -1], (item) ->
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

        SETEX plist, 5

  , callback

exports.getStorageQuota = (callback) ->
  cache.try 'linux.getStorageQuota', (SETEX) ->
    child_process.exec "sudo repquota -a", (err, stdout) ->
      logger.error err if err
      lines = _.filter stdout.split('\n')[5 ... -1], (i) -> i

      lines = _.map lines, (line) ->
        [username, __, size_used, size_soft, size_hard, inode_used, inode_soft, inode_hard, inode_grace] = line.split /\s+/

        if /days/.test inode_used
          [size_grace, inode_used, inode_soft, inode_hard, inode_grace] = [inode_used, inode_soft, inode_hard, inode_grace]

        return {
          username: username
          size_used: parseFloat (parseInt(size_used) / 1024).toFixed(1)
          inode_used: parseInt inode_used
        }

      SETEX _.indexBy(lines, 'username'), 60

  , callback

exports.getSystemInfo = (callback) ->
  cache.try 'linux.getSystemInfo', (SETEX) ->
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

        callback null, result

    , (err, result) ->
      logger.error err if err

      _.extend result,
        hostname: os.hostname()
        cpu: os.cpus()[0]['model']
        uptime: os.uptime()
        loadavg: _.map os.loadavg(), (i) -> parseFloat(i.toFixed(2))
        time: new Date()

      SETEX result, 30

  , callback

exports.getStorageInfo = (callback) ->
  cache.try 'linux.getStorageInfo', (SETEX) ->
    child_process.exec "df -h", (err, stdout) ->
      logger.error err if err
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

      used_per = parseInt (used / total * 100).toFixed()
      free_per = 100 - used_per

      SETEX
        used: used
        free: free
        total: total

        used_per: used_per
        free_per: free_per
      , 30

  , callback

exports.getResourceUsageByAccounts = (callback) ->
  cache.try 'linux.getResourceUsageByAccounts', (SETEX) ->
    async.parallel
      storage_quota: wrapAsync exports.getStorageQuota
      process_list: wrapAsync exports.getProcessList

    , (err, result) ->
      logger.error err if err
      resources_usage_by_accounts = []

      for username in _.union _.keys(monitor.resources_usage), _.keys(result.storage_quota)
        usage = monitor.resources_usage[username]
        storage = result.storage_quota[username]

        resources_usage_by_accounts.push
          username: username
          cpu: usage?.cpu ? 0
          memory: usage?.memory ? 0
          storage: storage?.size_used ? 0
          process: _.filter(result.process_list, (i) -> i.user == username).length

      SETEX resources_usage_by_accounts, 20

  , callback

exports.getResourceUsageByAccount = (account, callback) ->
  exports.getResourceUsageByAccounts (resources_usage_by_accounts) ->
    callback _.findWhere resources_usage_by_accounts,
      username: account.username
