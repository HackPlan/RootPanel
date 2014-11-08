{pluggable} = app

exports = module.exports = class SupervisorPlugin extends pluggable.Plugin
  @NAME: 'supervisor'
  @type: 'service'
  @dependencies: ['linux']

supervisor = require './supervisor'

exports.registerHook 'view.panel.scripts',
  path: '/plugin/linux/script/panel.css'

exports.registerHook 'view.panel.widgets',
  generator: (req, callback) ->
    exports.render 'widget', req,
      programSummary: supervisor.programSummary
    , callback

exports.registerServiceHook 'enable',
  filter: (req, callback) ->
    req.account.update
      $set:
        'pluggable.supervisor.programs': []
    , callback

exports.registerServiceHook 'disable',
  filter: (req, callback) ->
    supervisor.removePrograms req.account, ->
      supervisor.updateProgram req.account, null, ->
        callback()

app.express.use '/plugin/supervisor', require './router'
