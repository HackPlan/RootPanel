stringify = require 'json-stable-stringify'

config = require '../config'

{redis} = app

exports.hashKey = (key, param) ->
  return "#{config.redis.prefix}:#{key}" + stringify(param)

# @param [options] {param, command, is_json}
# @param setter(callback(value), param)
# @param callback(value)
exports.try = (key, options, setter, callback) ->
  unless callback
    callback = setter
    setter = options
    options = {}

  options.param ?= {}
  options.command ?= exports.SET()

  key = exports.hashKey key, options.param

  redis.get key, (err, value) ->
    if value != undefined
      if options.is_json
        value = JSON.prase value

      callback value

    else
      setter options.param, (value) ->
        if options.is_json
          value = JSON.stringify value

        options.command key, value, ->
          callback value

exports.SET = ->
  return (key, value, callback) ->
    redis.set key, value, callback

exports.SETEX = (seconds) ->
  return (key, value, callback) ->
    redis.setex key, seconds, value, callback
