MongoClient = require('mongodb').MongoClient
ObjectID = require('mongodb').ObjectID;
_ = require 'underscore'
db = require '../db'

module.exports = class Model
  constructor: (@data) ->

  @create : ->
    throw 'this function must be overrided'

  @createModels : (docs)->
    throw 'docs must be array' if not _.isArray docs
    results = []
    if docs.length is 1
      for doc in docs
        results.push @create doc
    else
      results = @create docs[0]
    results
  @table : ->
    "#{@name.toLowerCase()}s"

  @collection: ->
    db.mongo.collection @table()

  set : (key, value = null) ->
    if (_.isObject key) is 'object' then attrs = key else attrs[key] = value
    @data[k] = v for k, v of attrs
    return @

  get : (attr) ->
    @data[attr]

  insert : (data, callback) ->
    @collection().insert data, {w:1}, (err, docs) =>
      throw err if err
      if callback
        results = @constructor.createModels docs
        callback err, results

  update : (newObj , opts = {},callback) ->

  @find : (data, opts = {}, callback = null) ->
    if _.isFunction data
      callback = data
      data = {}
    else if _.isFunction opts
      callback = opts
      opts = {}
    @collection().find(data, opts).toArray (err, docs)=>
      throw err if err
      if callback
        results = @constructor.createModels docs
        callback err, results

  @findById: (id, callback) ->
    if _.isString id
      id = new ObjectID id

    @collection().findOne {_id: id}, (err, result) =>
      throw err if err
      result = @create result
      callback err, result
