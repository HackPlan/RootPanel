MongoClient = (require 'mongodb').MongoClient
ObjectID = require('mongodb').ObjectID
_ = require 'underscore'

config = (require './config').db

exports.connect = (callback = null)->
  #url = "mongodb://#{config.user}:#{config.passwd}@#{config.server}/#{config.name}"
  url = "mongodb://#{config.server}/#{config.name}"

  MongoClient.connect url, {}, (err, db) ->
    throw err if err
    exports.mongo = db

    callback(db) if callback

exports.collection = (name) ->
  return exports.mongo.collection name

exports.ObjectID = (id) ->
  try
    return new ObjectID id
  catch e
    return null

exports.buildModel = (that, mongo) ->
  that.find = (selector, options, callback) ->
    mongo.find selector, options, (err, cursor) ->
      throw err if err
      cursor.toArray (err, result) ->
        throw err if err
        callback result

  that.findOne = (selector, options, callback) ->
    mongo.findOne selector, options, (err, result) ->
      throw err if err
      callback result

  that.findId = (id, callback) ->
    if _.isString id
      id = exports.ObjectID id

    mongo.findOne
      _id: id
    , (err, result) ->
      throw err if err
      callback result

  that.update = (selector, documents, options, callback = null) ->
    mongo.update selector, documents, options, (err, result) ->
      throw err if err
      callback result if callback

  that.insert = (data, options, callback = null) ->
    mongo.insert data, options, (err, result) ->
      if _.isArray data
        callback result
      else
        callback result[0]

  that.remove = (selector, options, callback = null) ->
    mongo.remove selector, options, (err, result) ->
      throw err if err
      callback result if callback

exports.buildByXXOO = (xxoo, mongo) ->
  return (value, callback) ->
    selector = {}
    selector[xxoo] = value

    mongo.findOne selector, (err, result) ->
      throw err if err
      callback result
