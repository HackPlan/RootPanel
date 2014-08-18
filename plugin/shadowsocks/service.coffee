child_process = require 'child_process'
path = require 'path'
jade = require 'jade'
fs = require 'fs'

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
      password = mAccount.randomSalt()[0...10]

      mAccount.update _id: account._id,
        $set:
          'attribute.plugin.shadowsocks':
            port: port
            password: password
      , ->
        account.attribute.plugin.shadowsocks =
          port: port
          password: password

        module.exports.restart account, ->
          callback()

  delete: (account, callback) ->
    mAccount.update _id: account._id,
      $unset:
        'attribute.plugin.shadowsocks': true
    , ->
      # TODO delete iptables

      child_process.exec "sudo rm /etc/supervisor/conf.d/#{account.username}.conf", ->
        child_process.exec 'sudo supervisorctl reload', ->
          callback()

  restart: (account, callback) ->
    config_content = _.template (fs.readFileSync path.join(__dirname, 'template/config.conf')).toString(), account.attribute.plugin.shadowsocks

    # TODO iptables

    plugin.writeConfig "/etc/shadowsocks/#{account.username}.json", config_content, ->
      config_content = _.template (fs.readFileSync path.join(__dirname, 'template/supervisor.conf')).toString(),
        account: account

      plugin.writeConfig "/etc/supervisor/conf.d/#{account.username}.conf", config_content, ->
        child_process.exec 'sudo supervisorctl reload', ->
          callback()

  widget: (account, callback) ->
    jade.renderFile path.join(__dirname, 'view/widget.jade'),
      account: account
    , (err, html) ->
      throw err if err
      callback html
