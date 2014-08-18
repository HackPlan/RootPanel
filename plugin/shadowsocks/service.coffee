child_process = require 'child_process'
path = require 'path'
jade = require 'jade'

plugin = require '../../core/plugin'

mAccount = require '../../core/model/account'

generatePort = (callback) ->
  port = 10000 + Math.floor Math.random() * 10000

  mAccount.findOne
    'attribute.plugin.shadowsocks.port': port
  , (err, result) ->
    if result
      generatePort callback
    else
      callback port

module.exports =
  enable: (account, callback) ->
    generatePort (port) ->
      mAccount.update _id: account._id,
        $set:
          'attribute.plugin.shadowsocks':
            port: port
            password: mAccount.randomSalt()
      , ->
        module.exports.restart account, ->
          callback()

  delete: (account, callback) ->
    mAccount.update _id: account._id,
      $unset:
        'attribute.plugin.shadowsocks': true
    , ->
      #TODO kill process
      callback()

  restart: (account, callback) ->
    config_content = _.template (fs.readFileSync path.join(__dirname, 'template/config.conf')).toString(), account.attribute.plugin.shadowsocks

    plugin.writeConfig "/etc/shadowsocks/#{account.username}.conf", config_content, ->
      # kill process
      child_process.exec "nohup ss-server -c /etc/shadowsocks/#{account.username}.conf &", ->
        callback()

  widget: (account, callback) ->
    jade.renderFile path.join(__dirname, 'view/widget.jade'),
      account: account
    , (err, html) ->
      throw err if err
      callback html
