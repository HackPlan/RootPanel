MongoClient = require('mongodb').MongoClient

config = (require './config').db

url = "mongodb://#{config.user}:#{config.passwd}@#{config.server}/#{config.name}"
MongoClient.connect url, {}, (err, db) ->
  throw err if err

  exports.mongodb = db
