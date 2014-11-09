{_, child_process} = app.libs
{logger, utils} = app
{Account} = app.models

BILLING_BUCKET = config.plugins.shadowsocks.billing_bucket

exports.generateConfigure = (users, options) ->
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

exports.updateConfigure = (account, callback) ->

exports.monitoring = ->
