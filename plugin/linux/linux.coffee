fs = require 'fs'
async = require 'async'
_ = require 'underscore'

{cache} = app

exports.getPasswdMap = (callback) ->
  cache.try 'linux.getPasswdMap',
    command: cache.SETEX 120
    is_json: true
  , (callback) ->
    fs.readFile '/etc/passwd', (err, content) ->
      result = {}

      for line in _.compact(content.toString().split '\n')
        [username, password, uid] = line.split ':'
        result[uid] = username

      callback result
  , (passwd_map) ->
    callback passwd_map

exports.createUser = (account, callback) ->
  async.series [
    (callback) ->
      child_process.exec "sudo useradd -m -s /bin/bash #{account.username}", callback

    (callback) ->
      child_process.exec "sudo usermod -G #{account.username} -a www-data", callback

  ], (err) ->
    console.error err if err
    callback()

exports.deleteUser = (account, callback) ->
  async.series [
    (callback) ->
      child_process.exec "sudo pkill -u #{account.username}", callback

    (callback) ->
      child_process.exec "sudo userdel -rf #{account.username}", callback

    (callback) ->
      child_process.exec "sudo groupdel #{account.username}", callback

  ], (err) ->
    console.error err if err
    callback()

exports.setResourceLimit = (account, callback) ->
  storage_limit = account.resources_limit.storage
  soft_limit = (storage_limit * 1024 * 0.8).toFixed()
  hard_limit = (storage_limit * 1024 * 1.2).toFixed()
  soft_inode_limit = (storage_limit * 64 * 0.8).toFixed()
  hard_inode_limit = (storage_limit * 64 * 1.2).toFixed()

  child_process.exec "sudo setquota -u #{account.username} #{soft_limit} #{hard_limit} #{soft_inode_limit} #{hard_inode_limit} -a", (err) ->
    console.error err if err
    callback()
