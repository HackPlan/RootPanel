MongoClient = (require 'mongodb').MongoClient
config = (require './config').db

exports.connect = (callback = null)->
  #url = "mongodb://#{config.user}:#{config.passwd}@#{config.server}/#{config.name}"
  url = "mongodb://#{config.server}/#{config.name}"

  MongoClient.connect url, {}, (err, db) ->
    throw err if err
    exports.mongo = db

    callback(db) if callback
