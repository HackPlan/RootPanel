{express, ObjectID, _} = app.libs
{Account} = app.models
{requireInService} = app.middleware

module.exports = exports = express.Router()

supervisor = require './supervisor'

program_sample =
  _id: '53c96734c2dad7d6208a0fbe'
  name: 'my_app'
  command: '/home/jysperm/app'
  autostart: true
  autorestart: 'true/false/unexpected'
  directory: '/home/jysperm'

require_fields = ['name', 'command', 'autostart', 'autorestart', 'directory']
configurable_fields = ['command', 'autostart', 'autorestart', 'directory']

restrictProgramFields = (req, res, next) ->
  if req.body.name
    unless /^[A-Za-z0-9\/\._-]+$/.test req.body.name
      return res.error 'invalid_name'

  if req.body.command
    unless /^.*$/.test req.body.command
      return res.error 'invalid_command'

  if req.body.autostart != undefined
    req.body.autostart = if req.body.autostart then true else false

  if req.body.autorestart
    unless req.body.autorestart in ['true', 'false', 'unexpected']
      return res.error 'invalid_autorestart'

  if req.body.directory
    unless /^.*$/.test req.body.directory
      return res.error 'invalid_directory'

  next()

exports.use requireInService 'supervisor'

exports.param 'id', (req, res, next, id) ->
  Account.findOne
    'pluggable.supervisor.programs._id': ObjectID id
  , (err, account) ->
    req.program = _.find account?.pluggable.supervisor.programs, (program) ->
      return program._id.toString() == id

    unless req.program
      return res.error 'program_not_exist'

    unless account.id == req.account.id
      return res.error 'program_forbidden'

    next()

exports.post '/create_program', restrictProgramFields, (req, res) ->
  program = _.pick req.body, _.keys(program_sample)
  program._id = ObjectID()
  program.program_name = "@#{req.account.username}-#{program.name}"

  for field in require_fields
    unless field in _.keys req.body
      return res.error 'missing_field',
        name: field

  if req.body.name in req.account.pluggable.supervisor.programs
    return res.error 'name_exist'

  req.account.update
    $push:
      'pluggable.supervisor.programs': program
  , (err) ->
      return res.error err if err

    supervisor.writeConfig req.account, program, ->
      supervisor.updateProgram req.account, program, ->
        res.json {}

exports.post '/update_program/:id', restrictProgramFields, (req, res) ->
  for k, v of _.pick req.program, configurable_fields
    unless v == undefined
      req.program[k] = v

  Account.update
    'pluggable.supervisor.programs._id': req.program._id
  ,
    $set:
      'pluggable.supervisor.programs.$': req.program
  , (err) ->
    return res.error err if err

    supervisor.writeConfig req.account, req.program, ->
      supervisor.updateProgram req.account, req.program, ->
        res.json {}

exports.post '/remove_program/:id', (req, res) ->
  req.account.update
    $pull:
      'pluggable.supervisor.programs':
        _id: req.program._id
  , (err) ->
    return res.error err if err

    supervisor.removeConfig req.account, req.program, ->
      supervisor.updateProgram req.account, null, ->
        res.json {}

exports.get '/program_config/:id', (req, res) ->
  req.program.id = req.program._id
  delete req.program._id

  res.json req.program

exports.post '/program_control/:id', (req, res) ->
  unless req.body.action in ['start', 'stop', 'restart']
    return res.error 'invalid_action'

  supervisor.programControl req.account, req.program, req.body.action, ->
    res.json {}
