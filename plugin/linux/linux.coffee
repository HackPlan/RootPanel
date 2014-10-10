fs = require 'fs'
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
