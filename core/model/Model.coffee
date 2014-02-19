MongoClient = require('mongodb').MongoClient
ObjectID = require('mongodb').ObjectID;
_ = require 'underscore'
db = require '../db'

module.exports = class Model
  constructor: (@data) ->

  @create : ->
    throw 'this function must be overrided'

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

  save : (data, callback) ->
    @collection().insert data, {}, (err, docs) =>
      throw err if err
      if callback
        results = []
        if docs.length is 1
          for doc in doc
            results.push @create doc
        else
          results = @create docs[0]
        callback err, results

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
        results = []
        if docs.length is 1
          results = @create docs[0]
        else
          for doc in docs
            results.push @create doc
        callback err, results

  @findById: (id, callback) ->
    if _.isString id
      id = new ObjectID id

    @collection().findOne {_id: id}, (err, result) =>
      throw err if err
      result = @create result
      callback err, result
