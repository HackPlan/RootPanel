{express} = app.libs
{requireInService} = app.middleware

module.exports = exports = express.Router()

exports.use requireInService 'supervisor'

program_sample =
  _id: '53c96734c2dad7d6208a0fbe'
  name: 'my_app'
  command: '/home/jysperm/app'
  autostart: true
  autorestart: 'true/false/unexpected'
  directory: '/home/jysperm'

exports.post '/update_program', (req, res) ->

exports.get '/program_config', (req, res) ->

exports.post '/program_control', (req, res) ->
