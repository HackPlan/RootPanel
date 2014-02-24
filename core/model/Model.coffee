MongoClient = require('mongodb').MongoClient
ObjectID = require('mongodb').ObjectID;
_ = require 'underscore'
db = require '../db'

module.exports = class Model
  constructor: (@data) ->

  @create: ->
    throw 'this function must be overrided'

  @createModels: (docs)->
    if not _.isArray docs
      docs = [].push docs
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
    attrs = {}
    if (_.isObject key) is 'object' then attrs = key else attrs[key] = value
    @data[k] = v for k, v of attrs
    return @

  get: (attr) ->
    @data[attr]

  @insert: (data, callback = null) ->
    @collection().insert data, {w: 1}, (err, docs) =>
      throw err if err
      if callback
        results = @createModels docs
        callback err, results

  @removeById: (id, callback = null)->
    @collection().remove {_id: id}, {w: 1},(err,numberOfRemovedDocs)=>
      throw err if err
      if callback
        if numberOfRemovedDocs is 1
          callback null,numberOfRemovedDocs
        else
          callback 'there is  more then 1 documents with the same id'

  remove: (callback = null)->
    @constructor.removeById @data._id, callback

  @update: (selector, documents,opts = {w: 1, multi: true}, callback = null) ->
    if _.isFunction opts
      callback = opts
      opts = {w: 1,multi: true}
    throw 'arguments wrong' if not ((_.isObject selector) and (_.isObject documents))
    @collection().update selector, documents, opts, (err, numberUpdated) =>
      throw err if err
      if callback
        @find selector, (err, results) =>
          throw err if err
          results = @createModels doc
          callback err, results

  update: (documents, callback = null) ->
    if _.isFunction documents
      callback = documents
      documents = @data
    @constructor.collection().update {_id: @data._id}, documents,{w: 1}, (err, docs)=>
      throw err if err
      if callback
        @constructor.findById @data._id, (err, results)->
          throw err if err
          callback err, results

  @find: (selector, options = {}, callback = null) ->
    if _.isFunction selector
      callback = selector
      selector = {}
    else if _.isFunction options
      callback = options
      options = {}
    @collection().find(selector, options).toArray (err, docs)=>
      throw err if err
      if callback
        results = @createModels docs
        callback err, results
  #
  # 例：
  # User.findone {name: 'wangzi'},(err,result)->
  #   console.log result
  @findOne: (selector, opts = {},callback) ->
    if _.isFunction opts
      callback = opts
      opts = {}
    @collection().findOne selector,opts,(err,doc) ->
      throw err if err
      result = @create doc
      callback err, result

  # id为string
  @findById: (id, opts = {}, callback) ->
    @findOne {_id: id},opts,callback
