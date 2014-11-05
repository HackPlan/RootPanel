{express} = app.libs
{requireInService} = app.middleware

module.exports = exports = express.Router()

exports.use requireInService 'supervisor'

exports.post '/update_program', (req, res) ->

exports.get '/program_config', (req, res) ->

exports.post '/program_control', (req, res) ->
