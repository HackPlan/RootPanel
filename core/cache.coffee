stringify = require 'json-stable-stringify'
CounterCache = require 'counter-cache'
_ = require 'underscore'

config = require '../config'

{redis} = app

exports.counter = new CounterCache()

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

  if _.isEmpty options.param
    original_setter = setter
    setter = (param, callback) ->
      original_setter callback

  redis.get key, (err, value) ->
    if value != undefined and value != null
      if options.is_json
        value = JSON.parse value

      callback value

    else
      setter options.param, (value) ->
        if options.is_json
          value = JSON.stringify value

        options.command key, value, ->
          callback value

exports.delete = (key, param, callback) ->
  unless callback
    callback = param
    param = {}

  key = exports.hashKey key, param

  redis.del key, ->
    callback()

exports.SET = ->
  return (key, value, callback) ->
    redis.set key, value, callback

exports.SETEX = (seconds) ->
  return (key, value, callback) ->
    redis.setex key, seconds, value, callback
