{_} = app.libs
{pluggable} = app

exports = module.exports = class SupervisorPlugin extends pluggable.Plugin
  @NAME: 'supervisor'
  @type: 'service'
  @dependencies: ['linux']

supervisor = require './supervisor'

exports.registerHook 'view.panel.scripts',
  path: '/plugin/supervisor/script/panel.js'

exports.registerHook 'view.panel.styles',
  path: '/plugin/supervisor/style/panel.css'

exports.registerHook 'view.panel.widgets',
  generator: (req, callback) ->
    supervisor.programsStatus (programs_status) ->
      exports.render 'widget', req,
        programs_status: _.indexBy programs_status, 'name'
      , callback

exports.registerServiceHook 'enable',
  filter: (account, callback) ->
    account.update
      $set:
        'pluggable.supervisor.programs': []
    , callback

exports.registerServiceHook 'disable',
  filter: (account, callback) ->
    supervisor.removePrograms account, ->
      supervisor.updateProgram account, null, ->
        account.update
          $unset:
            'pluggable.supervisor': true
        , callback

app.express.use '/plugin/supervisor', require './router'
