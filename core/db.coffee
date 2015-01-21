{config} = app
{mongoose} = app.libs

mongoose.connect app.utils.mongodbUri config.mongodb

mongoose.connection.on 'error', (err) ->
  console.error err if err

mongoose.connection.on 'connected', ->
  db = mongoose.connection.db
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
