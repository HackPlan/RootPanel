{async, fs, child_process, _} = app.libs
{Account} = app.models

linux = require './linux'

fs.mkdirSync "#{__dirname}/../.backup/linux", 0o750

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
          if passwd_map[user]
            return callback

          console.log "removed /home/#{user}"

          async.series [
            (callback) ->
              child_process.exec "sudo mv /home/#{user} #{__dirname}/../.backup/linux/#{user}-#{utils.randomString(5)}", callback

            (callback) ->
              child_process.exec "sudo rm -r #{user}", callback
          ], callback
        , callback

  ], (err) ->
    throw err if err
    callback()
