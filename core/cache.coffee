{EventEmitter} = require 'events'
Redis = require 'ioredis'
_ = require 'lodash'
Q = require 'q'

###
  Public: Cache factory,
  You can access a global instance via `root.cache`.
###
module.exports = class CacheFactory extends EventEmitter
  constructor: ({host, port, password}) ->
    @redis = new Redis {host, port, password}

  getJSON: (keys) ->
    @redis.get(keys.join ':').then (result) ->
      try
        return JSON.parse result
      catch
        return null

  try: (keys, {setex}, setter) ->
    hashed = keys.join ':'

    @redis.get(hashed).then (value) =>
      if value != undefined and value != null
        try
          return JSON.parse value
        catch err
          return result

      else
        Q(setter keys).tap (value) =>
          if _.isObject value
            value = JSON.stringify value

          if setex
            @redis.setex hashed, setex, value
          else
            @redis.set hashed, value

  clean: (keys) ->
    client.del keys.join ':'
