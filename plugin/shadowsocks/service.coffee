child_process = require 'child_process'
path = require 'path'
jade = require 'jade'
fs = require 'fs'

plugin = require '../../core/plugin'

mAccount = require '../../core/model/account'
mBalance = require '../../core/model/balance'

BILLING_BUCKET = config.plugins.shadowsocks.billing_bucket

generatePort = (callback) ->
  port = 10000 + Math.floor Math.random() * 10000

  mAccount.findOne
    'attribute.plugin.shadowsocks.port': port
  , (err, result) ->
    if result
      generatePort callback
    else
      callback port

queryIptablesInfo = (callback) ->
  child_process.exec 'sudo iptables -n -v -L -t filter -x --line-numbers', (err, stdout) ->
    lines = stdout.split '\n'
    iptables_info = {}

    do ->
      CHAIN_OUTPUT = 'Chain OUTPUT'
      is_chain_output = false

      for item in lines
        if is_chain_output
          if item
            [num, pkts, bytes, prot, opt, in_, out, source, destination, prot, port] = item.split /\s+/

            unless num == 'num'
              port = port.match(/spt:(\d+)/)[1]

              iptables_info[port.toString()] =
                num: parseInt num
                pkts: parseInt pkts
                bytes: parseInt bytes
                port: parseInt port

        if item[0...CHAIN_OUTPUT.length] == CHAIN_OUTPUT
          is_chain_output = true

    callback iptables_info

module.exports =
  enable: (account, callback) ->
    generatePort (port) ->
      password = mAccount.randomString 10

      mAccount.findAndModify _id: account._id, {},
        $set:
          'attribute.plugin.shadowsocks':
            port: port
            password: password
            pending_traffic: 0
            last_traffic_value: 0
      , new: true, (err, account) ->
        child_process.exec "sudo iptables -I OUTPUT -p tcp --sport #{port}", ->
          child_process.exec 'sudo iptables-save | sudo tee /etc/iptables.rules', ->
            module.exports.restart account, ->
              callback()

  delete: (account, callback) ->
    queryIptablesInfo (iptables_info) ->
      port = account.attribute.plugin.shadowsocks.port

      billing_traffic = iptables_info[port].bytes - account.attribute.plugin.shadowsocks.last_traffic_value
      billing_traffic = iptables_info[port].bytes if billing_traffic < 0
      billing_traffic += account.attribute.plugin.shadowsocks.pending_traffic

      amount = billing_traffic / BILLING_BUCKET * config.plugins.shadowsocks.price_bucket

      mAccount.update _id: account._id,
        $unset:
          'attribute.plugin.shadowsocks': true
        $inc:
          'attribute.balance': -amount
      , ->
        async.parallel [
          (callback) ->
            child_process.exec "sudo iptables -D OUTPUT #{iptables_info[port].num}", callback

          (callback) ->
            child_process.exec 'sudo iptables-save | sudo tee /etc/iptables.rules', callback

          (callback) ->
            child_process.exec "sudo rm /etc/supervisor/conf.d/#{account.username}.conf", callback

          (callback) ->
            child_process.exec 'sudo supervisorctl update', callback
        ], ->
          if amount > 0
            mBalance.create account, 'service_billing', -amount,
              service: 'shadowsocks'
              traffic_mb: billing_traffic / BILLING_BUCKET * 100
              is_force: true
            , ->
              callback()
          else
            callback()

  restart: (account, callback) ->
    config_content = _.template (fs.readFileSync path.join(__dirname, 'template/config.conf')).toString(), account.attribute.plugin.shadowsocks

    plugin.writeConfig "/etc/shadowsocks/#{account.username}.json", config_content, ->
      child_process.exec "sudo chmod +r /etc/shadowsocks/#{account.username}.json", ->
        config_content = _.template (fs.readFileSync path.join(__dirname, 'template/supervisor.conf')).toString(),
          account: account

        plugin.writeConfig "/etc/supervisor/conf.d/#{account.username}.conf", config_content, ->
          child_process.exec 'sudo supervisorctl update', ->
            callback()

  monitoring: ->
    queryIptablesInfo (iptables_info) ->
      async.map _.values(iptables_info), (item, callback) ->
        {port, bytes} = item

        mAccount.findOne
          'attribute.plugin.shadowsocks.port': port
        , (err, account) ->
          unless account
            return callback()

          {pending_traffic, last_traffic_value} = account.attribute.plugin.shadowsocks

          new_traffic = bytes - last_traffic_value

          if new_traffic < 0
            new_traffic = bytes

          new_pending_traffic = pending_traffic + new_traffic

          billing_bucket = Math.floor pending_traffic / BILLING_BUCKET

          new_pending_traffic -= billing_bucket * BILLING_BUCKET

          if billing_bucket > 0
            amount = billing_bucket * config.plugins.shadowsocks.price_bucket

            mAccount.update _id: account._id,
              $set:
                'attribute.plugin.shadowsocks.pending_traffic': new_pending_traffic
                'attribute.plugin.shadowsocks.last_traffic_value': bytes
              $inc:
                'attribute.balance': -amount
            , (err) ->
              mBalance.create account, 'service_billing', -amount,
                service: 'shadowsocks'
                traffic_mb: billing_bucket * 100
                is_force: false
              , ->
                callback()
          else if pending_traffic != new_pending_traffic or last_traffic_value != bytes
            mAccount.update _id: account._id,
              $set:
                'attribute.plugin.shadowsocks.pending_traffic': new_pending_traffic
                'attribute.plugin.shadowsocks.last_traffic_value': bytes
            , (err) ->
              callback()
          else
            callback()

      , ->

  widget: (account, callback) ->
    mBalance.find
      account_id: account._id
      type: 'service_billing'
      'attribute.service': 'shadowsocks'
    .toArray (err, balance_logs) ->
      time_range =
        traffic_24hours: 24 * 3600 * 1000
        traffic_7days: 7 * 24 * 3600 * 1000
        traffic_30days: 30 * 24 * 3600 * 1000

      result = {}

      for name, range of time_range
        logs = _.filter balance_logs, (i) ->
          return i.created_at.getTime() > Date.now() - range

        result[name] = _.reduce logs, (memo, i) ->
          return memo + i.attribute.traffic_mb
        , 0

      jade.renderFile path.join(__dirname, 'view/widget.jade'), _.extend(result, account: account), (err, html) ->
        throw err if err
        callback html
