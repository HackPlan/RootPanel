{MongoClient, ObjectID} = require 'mongodb'
_ = require 'underscore'

exports.connect = (url, callback) ->
  db = {}

  MongoClient.connect url, {}, (err, client) ->
    throw err if err

    db =
      mongo: client

    db.ObjectID = (id) ->
      try
        return new ObjectID id
      catch e
        return null

    db.buildModel = (collection) ->
      model = db.mongo.collection collection

      model.findId = (id, callback) ->
        if _.isString id
          id = db.ObjectID id

        model.findOne
          _id: id
        , callback

      model.buildByXXOO = (xxoo) ->
        return (value, callback) ->
          selector = {}
          selector[xxoo] = value

          model.findOne selector, callback

      return model

    callback db
