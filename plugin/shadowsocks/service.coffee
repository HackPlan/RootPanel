delete: (account, callback) ->
  queryIptablesInfo (iptables_info) ->
    port = account.attribute.plugin.shadowsocks.port

    billing_traffic = iptables_info[port].bytes - account.attribute.plugin.shadowsocks.last_traffic_value
    billing_traffic = iptables_info[port].bytes if billing_traffic < 0
    billing_traffic += account.attribute.plugin.shadowsocks.pending_traffic

    amount = billing_traffic / BILLING_BUCKET * config.plugins.shadowsocks.price_bucket

    mAccount.update {_id: account._id},
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

  pluggable.writeConfig "/etc/shadowsocks/#{account.username}.json", config_content, ->
    child_process.exec "sudo chmod +r /etc/shadowsocks/#{account.username}.json", ->
      config_content = _.template (fs.readFileSync path.join(__dirname, 'template/supervisor.conf')).toString(),
        account: account

      pluggable.writeConfig "/etc/supervisor/conf.d/#{account.username}.conf", config_content, ->
        child_process.exec 'sudo supervisorctl update', ->
          callback()

restartAccount: (account, callback) ->
  child_process.exec "sudo supervisorctl restart shadowsocks-#{account.username}", ->
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

          mAccount.update {_id: account._id},
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
          mAccount.update {_id: account._id},
            $set:
              'attribute.plugin.shadowsocks.pending_traffic': new_pending_traffic
              'attribute.plugin.shadowsocks.last_traffic_value': bytes
          , (err) ->
            callback()
        else
          callback()

    , ->
