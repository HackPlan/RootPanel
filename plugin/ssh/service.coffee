module.exports =
  enable: (account, callback) ->
    console.log "enable SSH for #{account.username}"
    callback()

  pause: (account, callback) ->

  delete: (account, callback) ->
    console.log "delete SSH for #{account.username}"
    callback()
