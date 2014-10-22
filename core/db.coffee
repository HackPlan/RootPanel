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

module.exports = mongoose.connection
