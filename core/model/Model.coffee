MongoClient = require('mongodb').MongoClient
ObjectID = require('mongodb').ObjectID;
_ = require 'underscore'
assert = require 'assert'

db = require '../db'
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

