{async, fs, _, child_process} = app.libs
{Account} = app.models
{utils} = app

supervisor = require './supervisor'

fs.mkdirSync "#{__dirname}/../.backup/supervisor", 0o750

module.exports = (callback) ->
  async.series [
    (callback) ->
      Account.find
        'billing.service': 'supervisor'
        'pluggable.supervisor.programs.0':
          $exists: true
      , (err, accounts) ->
        async.eachSeries accounts, (account, callback) ->
          async.eachSeries account.pluggable.supervisor.programs, (program, callback) ->
            supervisor.writeConfig account, program, callback
          , callback
        , callback

    (callback) ->
      exists_configures = _.filter fs.readdirSync('/etc/supervisor/conf.d'), (file) ->
        return file[ ... 1] == '@'

      async.eachSeries exists_configures, (filename, callback) ->
        [__, username, name] = filename.match /@([^-]+)-(.*)/

        Account.findOne
          'username': username
          'billing.service': 'supervisor'
          'pluggable.supervisor.programs.name': name
        , (err, account) ->
          if account
            return callback()
          else
            console.log "removed /etc/supervisor/conf.d/#{filename}"
            backup_filename = "#{__dirname}/../.backup/supervisor/#{filename}-#{utils.randomString(5)}"
            child_process.exec "sudo mv /etc/supervisor/conf.d/#{filename} #{backup_filename}", callback

      , callback

    (callback) ->
      child_process.exec 'sudo service supervisor restart', callback

  ], (err) ->
    throw err if err
    callback()
