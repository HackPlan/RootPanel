{_, express} = app.libs
{requireAuthenticate} = app.middleware

module.exports = exports = express.Router()

exports.use requireAuthenticate

exports.param 'id', (req, res, next, id) ->

exports.get '/query', (req, res) ->

exports.post '/create', (req, res) ->

exports.post '/destroy/:id', (req, res) ->
