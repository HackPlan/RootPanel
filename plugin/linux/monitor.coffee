child_process = require 'child_process'
fs = require 'fs'

config = require '../../config.coffee'

mAccount = require '../../core/model/account'

REDIS_KEY = 'rp:linux:resources_usage'
REDIS_OVERVIEW = 'rp:linux:overview'
ITEM_IN_RESOURCES_LIST = 3600 * 1000 / config.plugins.linux.monitor_cycle

last_plist = []
passwd_cache = {}

exports.run = ->
  #setInterval exports.monitoring, config.plugins.linux.monitor_cycle

exports.loadpassword = (callback) ->
  fs.readFile '/etc/passwd', (err, content) ->
    throw err if err
    content = content.toString().split '\n'

    passwd_cache = {}

    for line in content
      if line
        [username, password, uid] = line.split ':'
        passwd_cache[uid] = username

    callback()

exports.monitoring = ->
  exports.loadpassword ->
    child_process.exec "ps awufx", (err, stdout, stderr) ->
      plist = stdout.split('\n')[1...-1]

      plist = _.reject plist, (item) ->
        return item[..3] == 'root'

      plist = _.map plist, (item) ->
        rx = /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)$/
        result = rx.exec item
        return {
          user: ->
            if passwd_cache[result[1]]
              return passwd_cache[result[1]]
            else
              return result[1]
          pid: result[2]
          cpu_per: result[3]
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

      async.parallel
        cpu: (callback) ->
          exports.monitoringCpu plist, callback

        memory: (callback) ->
          exports.monitoringMemory plist, callback

      , (err, result) ->
        app.redis.get REDIS_KEY, (err, resources_usage_list) ->
          resources_usage_list = JSON.parse resources_usage_list
          resources_usage_list.push result
          resources_usage_list = _.last resources_usage_list, ITEM_IN_RESOURCES_LIST

          account_usage = {}

          addAccountUsage = (account_name, type, value) ->
            account_usage[account_name] ?= {}

            if account_usage[account_name][type]
              account_usage[account_name][type] += value
            else
              account_usage[account_name][type] += value


          for item in resources_usage_list
            for account_name, cpu_usage of item.cpu
              addAccountUsage account_name, 'cpu', cpu_usage

            for account_name, memory_usage of item.memory
              addAccountUsage account_name, 'memory', memory_usage

          for account_name, usage of account_usage
            usage.memory = usage.memory / (resources_usage_list.length * config.plugins.linux.monitor_cycle * 1000)

          app.redis.setex REDIS_OVERVIEW, 60, JSON.stringify(account_usage), ->
            async.each _.keys(account_usage), (account_name) ->
              mAccount.byUsername account_name, (err, account) ->
                if account_usage[account_name].cpu > account.attribute.resources_limit.cpu
                  child_process.exec "pkill -SIGKILL -u #{account_name}", ->

                if account_usage[account_name].memory > account.attribute.resources_limit.memory
                  child_process.exec "pkill -SIGKILL -u #{account_name}", ->

                callback()
            , ->
              app.redis.set REDIS_KEY, JSON.stringify(resources_usage_list), ->
                last_plist = plist

exports.monitoringCpu = (plist, callback) ->
  total_time = {}

  findLastProcess = (process) ->
    return _.find last_plist, (i) ->
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
    addTime item.user, last_process.time - item.time

  for item in new_process
    addTime item.user, item.time

  callback null, total_time

exports.monitoringMemory = (plist, callback) ->
  total_memory = 0

  addMemory = (account_name, menory) ->
    if total_memory[account_name]
      total_memory[account_name] += menory
    else
      total_memory[account_name] = menory

  for item in plist
    addMemory item.user, ((item.rss / 1024) * config.plugins.linux.monitor_cycle / 1000).toFixed()

  callback null, total_memory
