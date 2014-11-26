{config} = app
{mongoose} = app.libs

{user, password, host, name} = config.mongodb

if user and password
  mongodb_uri = "mongodb://#{user}:#{password}@#{host}/#{name}"
else
  mongodb_uri = "mongodb://#{host}/#{name}"

mongoose.connect mongodb_uri

mongoose.connection.on 'error', (err) ->
  console.error err if err

mongoose.connection.on 'connected', ->
  db = mongoose.connection.db

  db.createCollection 'logs',
    capped: true
    size: 32 * 1024 * 1024
  , (err, cLogs) ->
    app.bunyanMongo.collection = cLogs
    app.bunyanMongo.dequeueCachedRecords()

  cOption = db.collection 'options'

  cOption.findOne
    key: 'db_version'
  , (err, db_version) ->
    unless db_version
      cOption.insert
        key: 'db_version'
        version: app.package.version
      , ->

module.exports = mongoose.connection
