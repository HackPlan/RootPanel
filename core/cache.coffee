stringify = require 'json-stable-stringify'
getParameterNames = require 'get-parameter-names'
CounterCache = require 'counter-cache'

{redis, config} = app
{_} = app.libs

exports.counter = new CounterCache()

exports.hashKey = (key) ->
  if _.isString key
    return "#{config.redis.prefix}:" + key
  else
    return "#{config.redis.prefix}:" + stringify key

# @param key: string|object
# @param setter(COMMAND(value, command_params...), key)
# @param callback(value)
exports.try = (key, setter, callback) ->
  original_key = key
  key = exports.hashKey key

  redis.get key, (err, value) ->
    if value != undefined and value != null
      try
        callback JSON.parse value
      catch e
        callback value

    else
      setter (value, command_params...) ->
        original_value = value

        if _.isObject value
          value = JSON.stringify value

        command = _.first getParameterNames setter
        command = exports[command.toUpperCase()]

        params = [key, value].concat command_params
        params.push ->
          callback original_value

        command.apply @, params

      , original_key

exports.refresh = (key, callback) ->
  redis.del exports.hashKey(key), ->
    callback()

exports.SET = (key, value, callback) ->
  redis.set key, value, callback

exports.SETEX = (key, value, seconds, callback) ->
  redis.setex key, seconds, value, callback
