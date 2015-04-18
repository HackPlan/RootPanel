module.exports = class LinuxMonitoring
  constructor: (@linux_server, {@monitor_cycle}) ->
    @cache = root.cache

  start: ->
    @cache.getJSON('linux:last_process_list').then (last_plist) =>
      @last_plist = last_plist ? []

      @monitoring().then =>
        setInterval =>
          @monitoring()
        , @monitor_cycle

  getCurrentUsages: ->
    return @current_usages

  monitoring: ->
    @linux_server.getProcessList().then (process_list) =>
      process_list = process_list.filter (process) ->
        return item.rss != 0

      Q.all [
        @cache.getJSON 'linux:recent_resources_usage'
        @linux_server.getMemoryUsages()
        @monitoringCpu process_list
        @monitoringMemory process_list
      ]

    .then ([recent_usages, global_memory_usages, cpu_usages, memory_usages]) =>
      recent_usages ?= []

      recent_usages.push
        cpu: cpu_usages
        memory: memory_usages

      recent_usages = _.last recent_usages, 3600 * 1000 / @monitor_cycle

      @current_usages = current_usages = {}

      logUsages = (user, type, usage) ->
        recent_usages[user] ?= {}
        recent_usages[user][type] ?= 0
        recent_usages[user][type] += usage

      for {cpu, memory} in recent_usages
        for user, usage of cpu
          logUsages user, 'cpu', usage

        for user, usage of memory
          logUsages user, 'memory', usage

      for user, usage of current_usages
        usage.memory = usage.memory / recent_usages.length / (@monitor_cycle / 1000)

      Q.all [
        @redis.setex 'linux:last_process_list', 3600, JSON.stringify process_list
        @redis.setex 'linux:recent_resources_usage', 60, JSON.stringify recent_usages
      ]

  monitoringCpu: (process_list) ->
    total = {}

    for {pid, user, command, time} in process_list
      last_process = _.findWhere @last_plist,
        pid: pid
        user: user
        command: command

      total[user] ?= 0

      if last_process
        if time - last_process.time > 0
          total[user] += time - last_process.time
      else
        total[user] += time

    return total

  monitoringMemory: (process_list) ->
    total = {}

    for {user, rss} in process_list
      total[user] ?= 0
      total[user] += parseInt ((rss / 1024) * @monitor_cycle / 1000).toFixed()

    return total
