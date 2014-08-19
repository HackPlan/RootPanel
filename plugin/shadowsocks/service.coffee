child_process = require 'child_process'
path = require 'path'
jade = require 'jade'
fs = require 'fs'

plugin = require '../../core/plugin'

mAccount = require '../../core/model/account'

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
                num: num
                pkts: pkts
                bytes: bytes
                port: port

        if item[0...CHAIN_OUTPUT.length] == CHAIN_OUTPUT
          is_chain_output = true

    callback iptables_info

module.exports =
  enable: (account, callback) ->
    generatePort (port) ->
      password = mAccount.randomString 16

      mAccount.update _id: account._id,
        $set:
          'attribute.plugin.shadowsocks':
            port: port
            password: password
      , ->
        account.attribute.plugin.shadowsocks =
          port: port
          password: password

        child_process.exec "sudo iptables -I OUTPUT -p tcp --sport #{port}", ->
          module.exports.restart account, ->
            callback()

  delete: (account, callback) ->
    mAccount.update _id: account._id,
      $unset:
        'attribute.plugin.shadowsocks': true
    , ->
      queryIptablesInfo (iptables_info) ->
        rule_id = iptables_info[account.attribute.plugin.shadowsocks.port].num
        child_process.exec "sudo iptables -D OUTPUT #{rule_id}", ->
          child_process.exec "sudo rm /etc/supervisor/conf.d/#{account.username}.conf", ->
            child_process.exec 'sudo supervisorctl reload', ->
              callback()

  restart: (account, callback) ->
    config_content = _.template (fs.readFileSync path.join(__dirname, 'template/config.conf')).toString(), account.attribute.plugin.shadowsocks

    plugin.writeConfig "/etc/shadowsocks/#{account.username}.json", config_content, ->
      config_content = _.template (fs.readFileSync path.join(__dirname, 'template/supervisor.conf')).toString(),
        account: account

      plugin.writeConfig "/etc/supervisor/conf.d/#{account.username}.conf", config_content, ->
        child_process.exec 'sudo supervisorctl reload', ->
          callback()

  widget: (account, callback) ->
    jade.renderFile path.join(__dirname, 'view/widget.jade'),
      account: account
    , (err, html) ->
      throw err if err
      callback html
