{pluggable} = app

module.exports = pluggable.createHelpers exports =
  name: 'supervisor'
  type: 'service'
  dependencies: ['linux']

exports.registerHook 'view.panel.scripts',
  path: '/plugin/linux/script/panel.css'

exports.registerHook 'view.panel.widgets',
  generator: (req, callback) ->
    exports.render 'widget', req, {}, callback

app.express.use '/plugin/supervisor', require './router'
