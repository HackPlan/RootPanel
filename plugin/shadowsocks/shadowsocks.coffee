{_, child_process, async, fs} = app.libs
{logger, utils} = app
{Account, Financials} = app.models

supervisor = require '../supervisor/supervisor'

BILLING_BUCKET = config.plugins.shadowsocks.billing_bucket

exports.initSupervisor = (callback) ->
  supervisor.programsStatus (program_status) ->
    async.each config.plugins.shadowsocks.available_ciphers, (method, callback) ->
      program_name = "shadowsocks-#{method}"

      if program_name in _.keys program_status
        return callback()

      shadowsocks_config_file = "/etc/shadowsocks/#{method}.json"
      configure = exports.generateConfigure [],
        method: method

      fs.writeFile shadowsocks_config_file, configure, ->
        supervisor.writeConfig {username: 'nobody'},
          command: "ssserver -c #{shadowsocks_config_file}"
          name: program_name
          autostart: true
          autorestart: true
        , ->
          supervisor.updateProgram {}, {program_name: program_name}, ->
            callback()

    , ->
      callback()

exports.generateConfigure = (users, options = {}) ->
  configure =
    server: '0.0.0.0'
    local_port: 1080
    port_password: {}
    timeout: 60
    method: options.method ? 'aes-256-cfb'
    workers: 2

  for user in users
    configure.port_password[user.port] = user.password

  return JSON.stringify configure

exports.generatePort = (port) ->
  port = 10000 + Math.floor Math.random() * 10000

  Account.findOne
    'pluggable.shadowsocks.port': port
  , (err, result) ->
    if result
      generatePort callback
    else
      callback port

exports.queryIptablesInfo = (callback) ->
  child_process.exec 'sudo iptables -n -v -L -t filter -x --line-numbers', (err, stdout) ->
    lines = stdout.split '\n'
    iptables_info = {}

    do ->
      CHAIN_OUTPUT = 'Chain OUTPUT'
      is_chain_output = false

      for item in lines
        if is_chain_output
          if item
            try
              [num, pkts, bytes, prot, opt, in_, out, source, destination, prot, port] = item.split /\s+/

              unless num == 'num'
                port = port.match(/spt:(\d+)/)[1]

                iptables_info[port.toString()] =
                  num: parseInt num
                  pkts: parseInt pkts
                  bytes: parseInt bytes
                  port: parseInt port

            catch e
              continue

        if item[ ... CHAIN_OUTPUT.length] == CHAIN_OUTPUT
          is_chain_output = true

    callback iptables_info

exports.initAccount = (account, callback) ->
  exports.generatePort (port) ->
    password = utils.randomString 10

    Account.findByIdAndUpdate account._id,
      $set:
        'pluggable.shadowsocks':
          port: port
          method: _.first config.plugins.shadowsocks.available_ciphers
          password: password
          pending_traffic: 0
          last_traffic_value: 0
    , (err, account) ->
      logger.error err if err

      child_process.exec "sudo iptables -I OUTPUT -p tcp --sport #{port}", ->
        child_process.exec 'sudo iptables-save | sudo tee /etc/iptables.rules', ->
          exports.updateConfigure account, ->
            callback()

exports.deleteAccount = (account, callback) ->
  queryIptablesInfo (iptables_info) ->
    {port, method} = account.pluggable.shadowsocks

    billing_traffic = iptables_info[port].bytes - account.pluggable.shadowsocks.last_traffic_value
    billing_traffic = iptables_info[port].bytes if billing_traffic < 0
    billing_traffic += account.pluggable.shadowsocks.pending_traffic

    amount = billing_traffic / BILLING_BUCKET * config.plugins.shadowsocks.price_bucket

    account.update
      $unset:
        'pluggable.shadowsocks': true
      $inc:
        'billing.balance': -amount
    , ->
      async.series [
        (callback) ->
          child_process.exec "sudo iptables -D OUTPUT #{iptables_info[port].num}", callback

        (callback) ->
          child_process.exec 'sudo iptables-save | sudo tee /etc/iptables.rules', callback

        (callback) ->
          exports.deleteAccountConfigure account, callback

        (callback) ->
          supervisor.updateProgram {}, {program_name: "shadowsocks-#{method}"}, callback

      ], ->
        if amount > 0
          Financials.create
            account_id: account._id
            type: 'usage_billing'
            amount: -amount
            payload:
              service: 'shadowsocks'
              traffic_mb: billing_traffic / (1000 * 1000)
          , ->
            callback()
        else
          callback()

exports.accountUsage = (account, callback) ->
  Financials.find
    account_id: account._id
    type: 'usage_billing'
    'payload.service': 'shadowsocks'
  , (err, financials) ->
    time_range =
      traffic_24hours: 24 * 3600 * 1000
      traffic_7days: 7 * 24 * 3600 * 1000
      traffic_30days: 30 * 24 * 3600 * 1000

    result = {}

    for name, range of time_range
      logs = _.filter financials, (i) ->
        return i.created_at.getTime() > Date.now() - range

      result[name] = _.reduce logs, (memo, i) ->
        return memo + i.payload.traffic_mb
      , 0

    callback result

exports.updateConfigure = (account, callback) ->
  {port, method, password} = account.pluggable.shadowsocks
  original_method = null

  async.eachSeries config.plugins.shadowsocks.available_ciphers, (method, callback) ->
    shadowsocks_config_file = "/etc/shadowsocks/#{method}.json"

    fs.readFile shadowsocks_config_file, (err, content) ->
      if port.toString() in _.keys JSON.parse(content).port_password
        original_method = method
        callback true
      else
        callback()

  , ->
    async.series [
      (callback) ->
        shadowsocks_config_file = "/etc/shadowsocks/#{method}.json"

        fs.readFile shadowsocks_config_file, (err, content) ->
          config = JSON.parse content
          config.port_password[port] = password

          fs.writeFile shadowsocks_config_file, JSON.stringify(config), ->
            callback()

      (callback) ->
        supervisor.updateProgram {}, {program_name: "shadowsocks-#{method}"}, ->
          callback()

      (callback) ->
        if original_method == original_method
          return callback()

        account = account.toObject()
        account.pluggable.shadowsocks.method = original_method

        exports.deleteAccountConfigure account, ->
          supervisor.updateProgram {}, {program_name: "shadowsocks-#{original_method}"}, ->
            callback()

    ], ->
      callback()

exports.deleteAccountConfigure = (account, callback) ->
  {port, method} = account.pluggable.shadowsocks
  shadowsocks_config_file = "/etc/shadowsocks/#{method}.json"

  fs.readFile shadowsocks_config_file, (err, content) ->
    config = JSON.parse content
    delete config.port_password[port]

    fs.writeFile shadowsocks_config_file, JSON.stringify(config), ->
      callback()

exports.monitoring = ->
  queryIptablesInfo (iptables_info) ->
    async.each _.values(iptables_info), (item, callback) ->
      {port, bytes} = item

      Account.findOne
        'pluggable.shadowsocks.port': port
      , (err, account) ->
        unless account
          return callback()

        {pending_traffic, last_traffic_value} = account.pluggable.shadowsocks

        new_traffic = bytes - last_traffic_value

        if new_traffic < 0
          new_traffic = bytes

        new_pending_traffic = pending_traffic + new_traffic

        billing_bucket = Math.floor pending_traffic / BILLING_BUCKET

        new_pending_traffic -= billing_bucket * BILLING_BUCKET

        if billing_bucket > 0
          amount = billing_bucket * config.plugins.shadowsocks.price_bucket

          account.update
            $set:
              'pluggable.shadowsocks.pending_traffic': new_pending_traffic
              'pluggable.shadowsocks.last_traffic_value': bytes
            $inc:
              'billing.balance': -amount
          , (err) ->
            logger.error err if err

            Financials.create
              account_id: account._id
              type: 'usage_billing'
              amount: -amount
              payload:
                service: 'shadowsocks'
                traffic_mb: (billing_bucket * BILLING_BUCKET) / 1000 * 1000
            , ->
              callback()

        else if pending_traffic != new_pending_traffic or last_traffic_value != bytes
          account.update
            $set:
              'pluggable.shadowsocks.pending_traffic': new_pending_traffic
              'pluggable.shadowsocks.last_traffic_value': bytes
          , (err) ->
            callback()

        else
          callback()

    , ->
