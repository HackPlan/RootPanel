linux = require '../linux/linux'

module.exports = pluggable.createHelpers exports =
  name: 'ssh'
  type: 'service'
  dependencies: ['linux']

exports.registerHook 'view.panel.scripts',
  path: '/plugin/ssh/style/panel.js'

exports.registerHook 'view.panel.widgets',
  generator: (req, callback) ->
    linux.getProcessList (process_list) ->
      process_list = _.filter process_list, (i) ->
        return i.user == account.username

      for item in plist
        item.command = (/^[^A-Za-z0.9//]*(.*)/.exec(item.command))[1]

      exports.render 'widget', req,
        process_list: process_list
      , (html) ->
        callback html

app.use '/plugin/ssh', require './router'
