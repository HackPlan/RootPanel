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
      results = @create docs[0]
    else
      for doc in docs
        results.push @create doc
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

  @insert : (data, callback = null) ->
    @collection().insert data, {w:1}, (err, docs) =>
      throw err if err
      if callback
        results = @createModels docs
        callback err, results
  @removeById: (id,callback = null)->
    @collection().remove {_id: id}, {w: 1},(err,numberOfRemovedDocs)=>
      throw err if err
      if callback
        if numberOfRemovedDocs is 1
          callback null,numberOfRemovedDocs
        else
          callback 'there is  more then 1 documents with the same id'

  update : (newObj , opts = {},callback) ->

  remove: (callback = null)->
    @constructor.removeById @data._id,callback

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
        results = @createModels docs
        callback err, results

  @findById: (id, callback) ->
    if _.isString id
      id = new ObjectID id

    @collection().findOne {_id: id}, (err, result) =>
      throw err if err
      result = @create result
      callback err, result
