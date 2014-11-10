{_} = app.libs
{pluggable} = app

exports = module.exports = class LinuxPlugin extends pluggable.Plugin
  @NAME: 'ssh'
  @type: 'service'
  @dependencies: ['linux']

linux = require '../linux/linux'

exports.registerHook 'view.panel.scripts',
  path: '/plugin/ssh/script/panel.js'

exports.registerHook 'view.panel.widgets',
  generator: (req, callback) ->
    linux.getProcessList (process_list) ->
      process_list = _.filter process_list, (i) ->
        return i.user == req.account.username

      for item in process_list
        item.command = (/^[^A-Za-z0.9//]*(.*)/.exec(item.command))[1]

      exports.render 'widget', req,
        process_list: process_list
      , callback

app.express.use '/plugin/ssh', require './router'
