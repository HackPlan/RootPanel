MongoClient = require('mongodb').MongoClient
ObjectID = require('mongodb').ObjectID;
_ = require 'underscore'
assert = require 'assert'
db = require '../db'
models =
  'User' : require './User'
# db.open (err,db)->
#   (db.collection 'users').findOne {name: '123'},(err,result)->
#       console.log result
module.exports = class Model
  constructor: (@attributes,opts = {}) ->

  @table : ->
    throw 'this function must be overrided'

  @collection: (db)->
    db.collection @table()

  @byId: (id, callback) ->
    throw 'id must be string' if !_.isString id

    id = new ObjectID id

    @collection().findOne {_id: id}, (err, result) ->
      throw err if err

      result = new @constructor result
      callback result

  set : (key, value = null) ->
    if (_.isObject key) is 'object' then attrs = key else attrs[key] = value
    @attributes[k] = v for k, v of attrs
    @
  get : (attr)->
    @attributes[attr]

  save : (attributes,callback)->
    db.open (err,db) =>
      @collection(db).insert attributes,{},(err,docs) ->
        assert.equal null,err
        if callback
          results = []
          model = models[@constructor.name]
          if _.isArray attributes
            for doc in doc
              results.push new model doc
          else
            results = new model docs[0]
          db.close()
          callback null,results