jsonStableStringify = require 'json-stable-stringify'
getParameterNames = require 'get-parameter-names'
redis = require 'redis'
_ = require 'underscore'
Q = require 'q'

###
  Public: Cache factory,
  You can access a global instance via `root.cache`.
###
module.exports = class CacheFactory
  constructor: ({host, port, password}) ->
    @redis = redis.createClient port, host,
      auth_pass: password

    _.extend @,
      get: Q.denodeify @redis.get.bind @redis
      del: Q.denodeify @redis.del.bind @redis
      set: Q.denodeify @redis.set.bind @redis
      setEx: Q.denodeify @redis.setex.bind @redis

  hashKey: (key) ->
    if _.isString key
      return key
    else
      return jsonStableStringify key

  getJSON: (key) ->
    @get(@hashKey key).then (result) ->
      try
        return JSON.parse result
      catch
        return null

  try: (key, setter) ->
    @tryHelper key, setter, =>
      @set arguments...

  tryExpire: (key, expired, setter) ->
    @tryHelper key, setter, (key, value) =>
      @setEx key, expired, value

  refresh: (key) ->
    @del @hashKey key

  tryHelper: (key, setter, operator) ->
    hashed_key = @hashKey key

    @get(hashed_key).then (value) ->
      Q().then ->
        if value in [undefined, null]
          Q(setter()).then (value) ->
            command(hashed_key, value).thenReject value
        else
          return value
