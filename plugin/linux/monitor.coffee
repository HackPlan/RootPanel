child_process = require 'child_process'
fs = require 'fs'

config = require '../../config.coffee'

mAccount = require '../../core/model/account'

REDIS_KEY = 'rp:linux:resources_usage'
REDIS_OVERVIEW = 'rp:linux:overview'
ITEM_IN_RESOURCES_LIST = 3600 * 1000 / config.plugins.linux.monitor_cycle

exports.last_plist = []
passwd_cache = {}

exports.resources_usage = {}
exports.storage_usage = {}

exports.run = ->
  exports.monitoring()
  setInterval exports.monitoring, config.plugins.linux.monitor_cycle

exports.loadPasswd = (callback) ->
  app.redis.get 'rp:passwd_cache', (err, result) ->
    if result
      passwd_cache = JSON.parse result
      callback passwd_cache
    else
      fs.readFile '/etc/passwd', (err, content) ->
        throw err if err
        content = content.toString().split '\n'

        passwd_cache = {}

        for line in content
          if line
            [username, password, uid] = line.split ':'
            passwd_cache[uid] = username

        app.redis.setex 'rp:passwd_cache', 120, JSON.stringify(passwd_cache), ->
          callback passwd_cache

exports.getProcessList = (callback) ->
  app.redis.get 'rp:process_list', (err, plist) ->
    if plist
      callback JSON.parse plist
    else
      exports.loadPasswd ->
        child_process.exec "ps awufxn", (err, stdout, stderr) ->
          plist = stdout.split('\n')[1...-1]

          plist = _.map plist, (item) ->
            rx = /^\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)$/
            result = rx.exec item
            return {
              user: do ->
                if passwd_cache[result[1]]
                  return passwd_cache[result[1]]
                else
                  return result[1]
              pid: parseInt result[2]
              cpu_per: parseInt result[3]
              mem_per: result[4]
              vsz: result[5]
              rss: parseInt result[6]
              tty: result[7]
              stat: result[8]
              start: result[9]
              time: do ->
                [minute, second] = result[10].split ':'
                return parseInt(minute) * 60 + parseInt(second)
              command: result[11]
            }

          app.redis.setex 'rp:process_list', 5, JSON.stringify(plist), ->
            callback plist

exports.monitoring = ->
  exports.loadPasswd ->
    exports.getProcessList (plist) ->
      plist = _.reject plist, (item) ->
        return item.rss == 0

      async.parallel
        cpu: (callback) ->
          exports.monitoringCpu plist, callback

        memory: (callback) ->
          exports.monitoringMemory plist, callback

      , (err, result) ->
        app.redis.get REDIS_KEY, (err, resources_usage_list) ->
          resources_usage_list = JSON.parse(resources_usage_list) ? []
          resources_usage_list.push result
          resources_usage_list = _.last resources_usage_list, ITEM_IN_RESOURCES_LIST

          account_usage = {}

          addAccountUsage = (account_name, type, value) ->
            account_usage[account_name] ?= {}

            if account_usage[account_name][type]
              account_usage[account_name][type] += value
            else
              account_usage[account_name][type] = value

          for item in resources_usage_list
            for account_name, cpu_usage of item.cpu
              addAccountUsage account_name, 'cpu', cpu_usage

            for account_name, memory_usage of item.memory
              addAccountUsage account_name, 'memory', memory_usage

          for account_name, usage of account_usage
            usage.memory = usage.memory / resources_usage_list.length / config.plugins.linux.monitor_cycle * 1000

          exports.resources_usage = account_usage

          app.redis.setex REDIS_OVERVIEW, 60, JSON.stringify(account_usage), ->
            async.each _.keys(account_usage), (account_name, callback) ->
              mAccount.byUsername account_name, (err, account) ->
                unless account
                  return callback()

                if account_usage[account_name].cpu > account.attribute.resources_limit.cpu
                  child_process.exec "sudo pkill -SIGKILL -u #{account_name}", ->

                if account_usage[account_name].memory > account.attribute.resources_limit.memory
                  child_process.exec "sudo pkill -SIGKILL -u #{account_name}", ->

                callback()
            , ->
              app.redis.set REDIS_KEY, JSON.stringify(resources_usage_list), ->
                exports.last_plist = plist

exports.monitoringStorage = (callback) ->
  app.redis.get 'rp:storage_usage', (err, result) ->
    if result
      callback JSON.parse result
    else
      child_process.exec "sudo repquota -a", (err, stdout, stderr) ->
        lines = stdout.split('\n')[5...-1]
        lines = _.filter lines, (i) -> i

        lines = _.map lines, (line) ->
          fields = _.filter line.split(' '), (i) -> i and i != ' '
          [username, __, size_used, size_soft, size_hard, inode_used, inode_soft, inode_hard, inode_grace] = fields

          if /days/.test inode_used
            [size_grace, inode_used, inode_soft, inode_hard, inode_grace] = [inode_used, inode_soft, inode_hard, inode_grace]

          return {
            username: username
            size_used: size_used
            inode_used: inode_used
          }

        exports.storage_usage = {}

        for item in lines
          exports.storage_usage[item.username] = item

        app.redis.setex 'rp:storage_usage', 3, JSON.stringify(exports.storage_usage), ->
          callback()

exports.monitoringCpu = (plist, callback) ->
  total_time = {}

  findLastProcess = (process) ->
    return _.find exports.last_plist, (i) ->
      return i.pid == process.pid and i.user == process.user and i.command == process.command

  addTime = (account_name, time) ->
    if total_time[account_name]
      total_time[account_name] += time
    else
      total_time[account_name] = time

  exist_process = _.filter plist, (item) ->
    return findLastProcess item

  new_process = _.filter plist, (item) ->
    return not findLastProcess item

  for item in exist_process
    last_process = findLastProcess item
    addTime item.user, item.time - last_process.time

  for item in new_process
    addTime item.user, item.time

  callback null, total_time

exports.monitoringMemory = (plist, callback) ->
  total_memory = {}

  addMemory = (account_name, menory) ->
    if total_memory[account_name]
      total_memory[account_name] += menory
    else
      total_memory[account_name] = menory

  for item in plist
    addMemory item.user, parseInt ((item.rss / 1024) * config.plugins.linux.monitor_cycle / 1000).toFixed()

  callback null, total_memory
