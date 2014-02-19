Db = (require 'mongodb').Db
Server = (require 'mongodb').Server
assert = require 'assert'
config = (require './config').db

# url = "mongodb://#{config.user}:#{config.passwd}@#{config.server}/#{config.name}"
url = "mongodb://127.0.0.1:27017/#{config.name}"
# MongoClient.connect url, {}, (err, db) ->
#   assert.equal null,err
#   module.exports = db

module.exports = new Db config.name, (new Server 'localhost',27017),safe : true