{async, fs, child_process, _} = app.libs
{Account} = app.models
{utils} = app

linux = require './linux'

unless fs.existsSync "#{__dirname}/../../.backup/linux"
  fs.mkdirSync "#{__dirname}/../../.backup/linux", 0o750

module.exports = (callback) ->
  exists_users = _.filter fs.readdirSync('/home'), (file) ->
    return fs.statSync("/home/#{file}").isDirectory()

  async.series [
    (callback) ->
      Account.find
        'billing.services': 'linux'
      , (err, accounts) ->
        async.eachSeries accounts, (account, callback) ->
          if account.username in exists_users
            linux.setResourceLimit account, callback
          else
            console.log "created linux user for #{account.username}"

            linux.createUser account, ->
              linux.setResourceLimit account, callback

        , callback

    (callback) ->
      linux.getPasswdMap (passwd_map) ->
        async.eachSeries exists_users, (user, callback) ->
          if user in _.values passwd_map
            return callback()

          console.log "removed /home/#{user}"
          backup_filename = "#{__dirname}/../../.backup/linux/#{user}-#{utils.randomString(5)}"
          child_process.exec "sudo mv /home/#{user} #{backup_filename}", callback

        , callback

  ], (err) ->
    throw err if err
    callback()
