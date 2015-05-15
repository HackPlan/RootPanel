os = require 'os'
_ = require 'lodash'
Q = require 'q'

class LinuxServer
  constructor: (@server) ->

  getUsers: ->
    @server.readFile('/etc/passwd').then (content) ->
      return _.compact(content.toString().split '\n').map (line) ->
        [user, password, uid] = line.split ':'

        return {
          uid: uid
          user: username
          password: password
        }

  getGroups: ->
    @server.readFile('/etc/group').then (content) ->
      return _.compact(content.toString().split '\n').map (line) ->
        [name, password, gid] = line.split ':'

        return {
          gid: gid
          name: name
          password: password
        }

  createUser: (user) ->
    Q.all [
      @server.command "sudo useradd -m -s /bin/bash #{user}"
      @server.command "sudo usermod -G #{user} -a www-data"
    ]

  setPassword: (user, password) ->
    @server.exec 'sudo',
      params: ['chpasswd']
      stdin: "#{user}:#{password}"

  deleteUser: (user) ->
    Q.all [
      @server.command "sudo pkill -u #{user}"
      @server.command "sudo userdel -rf #{user}"
      @server.command "sudo groupdel #{user}"
    ]

  killProcess: (user, pid) ->
    @server.command "sudo su #{user} -c 'kill #{pid}'"

  killProcesses: (user) ->
    @server.command "sudo pkill -SIGKILL -u #{user}"

  getMemoryUsages: ->
    @server.readFile('/proc/meminfo').then (content) ->
      meminfo = parseColonMapping content

      [total, free, buffers, cached, swap_free, swap_total] = [
        'MemTotal', 'MemFree', 'Buffers', 'Cached', 'SwapFree', 'SwapTotal'
      ].map (key) ->
        return parseInt meminfo[key].match /\d+/

      return {
        used: total - free - buffers - cached
        cached: cached
        buffers: buffers
        free: free
        total: total

        swap:
          total: swap_total
          free: swap_free
          used: swap_total - swap_free
      }

  getStorageUsages: ->
    @server.command('df -h').then ({stdout}) ->
      disks = stdout.split('\n').map (line) ->
        [dev, size, used, available, used_per, mounted] = line.split /\s+/

        return {
          mounted: mounted
          dev: dev
          size: parseInt size?.match(/\d+/)
          used: parseInt used?.match(/\d+/)
          available: available
          used_per: used_per
        }

  getProcessList: ->
    Q.all([
      @getUsers(), @server.command('sudo ps awufxn')
    ]).then ([users, {stdout}]) ->
      return stdout.split('\n')[1 ... -1].map (line) ->
        [uid, pid, cpu, mem, vsz, rss, tty, stat, start, time, command...] = line.split /\s+/

        [minutes, seconds] = time.split ':'
        time = parseInt(minutes) * 60 + parseInt(seconds)

        return {
          user: _.findWhere(users, uid: parseInt uid).user ? uid
          pid: parseInt pid
          cpu: parseInt cpu
          mem: parseInt mem
          vsz: parseInt vsz
          rss: parseInt rss
          tty: tty
          stat: stat
          start: start
          time: time
          command: command.join ' '
        }

  getStorageQuota: ->
    @server.command('sudo repquota -a').then ({stdout}) ->
      return _.compact(stdout.split('\n')[5 ... -1]).map (line) ->
        [user, __, used, soft, hard, inode_used, inode_soft, inode_hard, inode_grace] = line.split /\s+/

        if inode_used.match /days/
          [grace, inode_used, inode_soft, inode_hard, inode_grace] = [inode_used, inode_soft, inode_hard, inode_grace]

        return {
          user: user
          used: parseInt used
          inode_used: parseInt inode_used
        }

  # TODO: Support friendly string.
  setStorageQuota: (username, {soft, hard, inode_soft, inode_hard}) ->
    [soft, hard, inode_soft, inode_hard] = [soft, hard, inode_soft, inode_hard].map (number) ->
      return number.toFixed()

    @server.command "sudo setquota -u #{username} #{soft} #{hard} #{inode_soft} #{inode_hard} -a"

  # TODO: Use @server to get system info.
  getSystemInfo: ->
    @server.read('/etc/issue').then (content) ->
      address = []

      for name, info of os.networkInterfaces()
        for item in info
          unless item.internal
            address.push item.address

      return {
        hostname: os.hostname()
        cpu: os.cpus()[0]['model']
        uptime: os.uptime()
        system: content.toString().replace(/\\\w/g, '').trim()
        loadavg: os.loadavg()
        address: address
        time: new Date()
      }

parseColonMapping = (content) ->
  mapping = {}

  for line in content.toString().split '\n'
    [key, value...] =  line.split ':'
    value = value.join ':'
    mapping[key.trim()] = value.trim()

  return mapping
