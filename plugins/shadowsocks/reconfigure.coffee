{async, _, child_process} = app.libs
{Account} = app.models
{config, utils} = app

shadowsocks = require './shadowsocks'

module.exports = (callback) ->
  async.series [
    (callback) ->
      async.each config.plugins.shadowsocks.available_ciphers, (method, callback) ->
        shadowsocks.writeSupervisorConfigure method, callback
      , callback

    (callback) ->
      default_method = _.first config.plugins.shadowsocks.available_ciphers

      Account.find
        'billing.service': 'shadowsocks'
      , (err, accounts) ->
        async.eachSeries accounts, (account, callback) ->
          {port, method, password} = account.pluggable.shadowsocks

          unless method
            console.log "created shadowsocks method for #{account.username}}"
            account.pluggable.shadowsocks.method = default_method
            account.markModified 'pluggable.shadowsocks.method'

          unless password
            console.log "created shadowsocks password for #{account.username}}"
            account.pluggable.shadowsocks.password = utils.randomString 10
            account.markModified 'pluggable.shadowsocks.password'

          if port
            account.save callback
          else
            shadowsocks.generatePort (port) ->
              console.log "created shadowsocks port for #{account.username}}"
              account.pluggable.shadowsocks.port = port
              account.markModified 'pluggable.shadowsocks.port'
              account.save callback

        , callback

    (callback) ->
      shadowsocks.queryIptablesInfo (iptables_info) ->
        Account.find
          'billing.service': 'shadowsocks'
        , (err, accounts) ->
          async.series [
            (callback) ->
              async.eachSeries accounts, (account, callback) ->
                port = iptables_info[account.pluggable.shadowsocks.port]

                if port
                  callback()
                else
                  child_process.exec "sudo iptables -I OUTPUT -p tcp --sport #{port}", callback
              , callback

            (callback) ->
              async.eachSeries _.keys(iptables_info), (port) ->
                matched_account = _.find accounts, (account) ->
                  return account.pluggable.shadowsocks.port == port

                if matched_account
                  callback()
                else
                  child_process.exec "sudo iptables -D OUTPUT #{iptables_info[port].num}", callback
              , callback

          ], callback

    (callback) ->
      child_process.exec 'sudo iptables-save | sudo tee /etc/iptables.rules', callback

    (callback) ->
      shadowsocks.updateConfigure callback

  ], (err) ->
    throw err if err
    callback()
