child_process = require 'child_process'
os = require 'os'
fs = require 'fs'
async = require 'async'
_ = require 'underscore'

{config} = app
{mAccount} = app.models

linux = require './linux'

last_plist = []

exports.resources_usage = {}

exports.run = ->
  exports.monitoring ->
    setInterval ->
      exports.monitoring ->
    , config.plugins.linux.monitor_cycle

exports.monitoring = (callback) ->
  REDIS_KEY = "#{config.redis.prefix}:linux.recent_resources_usage"
  ITEM_IN_RESOURCES_LIST = 3600 * 1000 / config.plugins.linux.monitor_cycle

  linux.getMemoryInfo (err, memory_info) ->
    linux.getProcessList (plist) ->
      plist = _.reject plist, (item) ->
        return item.rss == 0

      async.parallel
        cpu: (callback) ->
          exports.monitoringCpu plist, callback

        memory: (callback) ->
          exports.monitoringMemory plist, callback

      , (err, result) ->
        app.redis.get REDIS_KEY, (err, recent_resources_usage) ->
          recent_resources_usage = JSON.parse(recent_resources_usage) ? []
          recent_resources_usage.push result
          recent_resources_usage = _.last recent_resources_usage, ITEM_IN_RESOURCES_LIST

          resources_usage = {}

          IncreaseAccountUsage = (username, type, value) ->
            resources_usage[username] ?= {}

            if resources_usage[username][type]
              resources_usage[username][type] += value
            else
              resources_usage[username][type] = value

          for item in recent_resources_usage
            for account_name, cpu_usage of item.cpu
              IncreaseAccountUsage account_name, 'cpu', cpu_usage

            for account_name, memory_usage of item.memory
              IncreaseAccountUsage account_name, 'memory', memory_usage

          for username, usage of resources_usage
            usage.memory = usage.memory / recent_resources_usage.length / config.plugins.linux.monitor_cycle * 1000

          async.each _.keys(resources_usage), (username, callback) ->
            mAccount.search username, (err, account) ->
              unless account
                return callback()

              if os.loadavg()[0] > 1
                if resources_usage[username].cpu > account.resources_limit.cpu
                  child_process.exec "sudo pkill -SIGKILL -u #{username}", ->

              if memory_info.used_per > 75
                if resources_usage[username].memory > account.resources_limit.memory
                  child_process.exec "sudo pkill -SIGKILL -u #{username}", ->

              callback()
          , ->
            app.redis.set REDIS_KEY, JSON.stringify(recent_resources_usage), ->
              exports.resources_usage = resources_usage
              last_plist = plist
              callback()

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
