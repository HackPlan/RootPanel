#!/usr/bin/env coffee

require '../app'

{async, fs, _} = app.libs
{config, pluggable} = app
{Account} = app.models

Account.find
  'billing.plans.0':
    $exists: true
, (err, accounts) ->
  async.eachSeries accounts, (account, callback) ->
    original_account = account

    services = _.flatten _.compact _.map account.billing.plans, (plan) ->
      return config.plans[plan]?.services

    if _.isEqual account.billing.services, services
      return callback()

    Account.findByIdAndUpdate account._id,
      $set:
        'billing.services': services
    , (err, account) ->
      services = account.billing.services
      original_services = original_account.billing.services

      async.series [
        (callback) ->
          async.each _.difference(services, original_services), (service_name, callback) ->
            console.log "#{account.username} enabled #{service_name}"

            async.each pluggable.selectHook(account, "service.#{service_name}.enable"), (hook, callback) ->
              hook.filter account, callback
            , callback
          , callback

        (callback) ->
          async.each _.difference(original_services, services), (service_name, callback) ->
            console.log "#{account.username} disabled #{service_name}"

            async.each pluggable.selectHook(account, "service.#{service_name}.disable"), (hook, callback) ->
              hook.filter account, callback
            , callback
          , callback
      ], callback

  , ->
    available_plugins = _.union config.plugin.available_extensions, config.plugin.available_services

    async.eachSeries available_plugins, (plugin_name, callback) ->
      filename = "#{__dirname}/../plugin/#{plugin_name}/reconfigure.coffee"

      unless fs.existsSync filename
        return callback()

      require(filename) ->
        callback()

    , ->
      console.log 'Reconfigure Finish'
      process.exit 0
