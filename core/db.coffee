{config} = app
{mongoose} = app.libs

{user, password, host, name} = config.mongodb

if user and password
  mongodb_uri = "mongodb://#{user}:#{password}@#{host}/#{name}"
else
  mongodb_uri = "mongodb://#{host}/#{name}"

module.exports = mongoose.createConnection mongodb_uri

exports.mongodb_uri = mongodb_uri

mongoose.connection.on 'error', (err) ->
  console.error err if err
