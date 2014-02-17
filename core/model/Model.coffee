MongoClient = require('mongodb').MongoClient
BSON = require('mongodb').BSONPure;
_ = require 'underscore'

db = require '../db'

module.exports = class Model
  db: db.mongodb

  constructor: (@data) ->

  collection: ->
    throw 'this function must be overrided'

  byId: (id, callback) ->
    if _.isString id
      id = BSON.ObjectID id

    @collection().findOne {_id: id}, (err, result) ->
      throw err if err

      result = new @(result)
      callback(result)
