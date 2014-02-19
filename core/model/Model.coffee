MongoClient = require('mongodb').MongoClient
ObjectID = require('mongodb').ObjectID;
_ = require 'underscore'
db = require '../db'

module.exports = class Model
  constructor: (@data) ->

  @create: ->
    throw 'this function must be overrided'

  @createModels: (docs)->
    throw 'docs must be array' if not _.isArray docs
    results = []
    if docs.length is 1
      results = @create docs[0]
    else
      for doc in docs
        results.push @create doc
    results
  @table: ->
    "#{@name.toLowerCase()}s"

  @collection: ->
    db.mongo.collection @table()

  set: (key, value = null) ->
    if (_.isObject key) is 'object' then attrs = key else attrs[key] = value
    @data[k] = v for k, v of attrs
    return @

  get: (attr) ->
    @data[attr]

  @insert: (data, callback = null) ->
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

  remove: (callback = null)->
    @constructor.removeById @data._id,callback

  @update: (selector, documents,opts = {w: 1,multi: true},callback = null) ->
    if _.isFunction opts
      callback = opts
      opts = {w: 1,multi: true}
    throw 'arguments wrong' if not ((_.isObject selector) and (_.isObject documents))
    @collection().update selector,documents,opts,(err,numberUpdated)=>
      throw err if err
      if callback
        @find selector,(err,results)->
          throw err if err
          callback err,results


  update: (documents , opts = {w:1},callback = null) ->
    if _.isFunction opts
      callback = opts
      opts = {w: 1}
    throw 'arguments wrong' if not _.isObject documents
    @constructor.collection().update {_id: @data._id},documents,opts,(err,doc)=>
      throw err if err
      if callback
        results = @constructor.createModels doc
        callback err,results



  @find: (selector, opts = {}, callback = null) ->
    if _.isFunction selector
      callback = selector
      selector = {}
    else if _.isFunction opts
      callback = opts
      opts = {}
    @collection().find(selector, opts).toArray (err, docs)=>
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
