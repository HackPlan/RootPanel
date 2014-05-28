MongoClient = (require 'mongodb').MongoClient
ObjectID = require('mongodb').ObjectID
_ = require 'underscore'

config = require './config'

exports.db = {}

exports.connect = (callback) ->
  MongoClient.connect config.mongodb, {}, (err, db) ->
    throw err if err
    exports.mongo = db

    callback db

exports.buildModel = (collection) ->
  model = exports.mongo.collection collection

  model.findId = (id, callback) ->
    if _.isString id
      id = exports.ObjectID id

    mongo.findOne
      _id: id
    , callback

exports.ObjectID = (id) ->
  try
    return new ObjectID id
  catch e
    return null

exports.buildByXXOO = (xxoo, mongo) ->
  return (value, callback) ->
    selector = {}
    selector[xxoo] = value

    mongo.findOne selector, callback
