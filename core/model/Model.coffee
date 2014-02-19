MongoClient = require('mongodb').MongoClient
ObjectID = require('mongodb').ObjectID;
_ = require 'underscore'
assert = require 'assert'
db = require '../db'

module.exports = class Model
  constructor: (@data) ->

  @create : ->
    throw 'this function must be overrided'

  @table : ->
    "#{@name.toLowerCase()}s"

  @collection: (db) ->
    db.collection @table()

  set : (key, value = null) ->
    if (_.isObject key) is 'object' then attrs = key else attrs[key] = value
    @data[k] = v for k, v of attrs
    return @

  get : (attr) ->
    @data[attr]

  save : (data, callback) ->
    db.open (err,db) =>
      @collection(db).insert data, {}, (err, docs) =>
        assert.equal null, err
        db.close()
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
    db.open (err,db) =>
      @collection(db).find(data, opts).toArray (err, docs)=>
        assert.equal null, err
        db.close()
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

    db.open (err,db) =>
      @collection().findOne {_id: id}, (err, result) =>
        throw err if err
        db.close()
        result = @create result
        callback err, result
