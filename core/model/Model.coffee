MongoClient = require('mongodb').MongoClient
ObjectID = require('mongodb').ObjectID;
_ = require 'underscore'
assert = require 'assert'
db = require '../db'
# db.open (err,db)->
#   (db.collection 'users').find().toArray (err,result)->
#       console.log result
module.exports = class Model
  constructor: (@attributes,opts = {}) ->

  @create : ->
    throw 'this function must be overrided'

  @table : ->
    throw 'this function must be overrided'

  @collection: (db)->
    db.collection @table()
  set : (key, value = null) ->
    if (_.isObject key) is 'object' then attrs = key else attrs[key] = value
    @attributes[k] = v for k, v of attrs
    @
  get : (attr)->
    @attributes[attr]

  save : (attributes,callback)->
    db.open (err,db) =>
      @collection(db).insert attributes,{},(err,docs) =>
        assert.equal null,err
        db.close()
        if callback
          results = []
          if docs.length is 1
            for doc in doc
              results.push @create doc
          else
            results = @create docs[0]
          callback null,results
  @find : (attrs,opts = {},callback = null)->
    if _.isFunction attrs
      callback = attrs
      attrs = {}
    else if _.isFunction opts
      callback = opts
      opts = {}
    db.open (err,db) =>
      @collection(db).find(attrs,opts).toArray (err,docs)=>
        assert.equal null,err
        db.close()
        if callback
          results = []
          if docs.length is 1
            results = @create docs[0]
          else
            for doc in docs
              results.push @create doc
          callback null,results

  @findById: (id, callback = null) ->
    throw 'id must be string' if !_.isString id
    db.open (err,db) =>
      @collection().findOne {_id: new ObjectID id}, (err, result) =>
        throw err if err
        db.close()
        result = @create result
        if callback
          callback result