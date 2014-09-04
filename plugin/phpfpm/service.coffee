child_process = require 'child_process'
jade = require 'jade'
path = require 'path'
tmp = require 'tmp'
fs = require 'fs'

plugin = require '../../core/pluggable'

mAccount = require '../../core/model/account'

module.exports =
  enable: (account, callback) ->
    mAccount.update _id: account._id,
      $set:
        'attribute.plugin.phpfpm.is_enable': false
    , ->
      callback()

  delete: (account, callback) ->
    if account.attribute.plugin.phpfpm.is_enable
      this.switch account, false, callback
    else
      callback()

  switch: (account, is_enable, callback) ->
    restartPhpfpm = ->
      child_process.exec 'sudo service php5-fpm restart', (err) ->
        throw err if err
        callback()

    if is_enable
      config_content = _.template (fs.readFileSync path.join(__dirname, 'template/fpm-pool.conf')).toString(),
        account: account

      pluggable.writeConfig "/etc/php5/fpm/pool.d/#{account.username}.conf", config_content, ->
        restartPhpfpm()
    else
      child_process.exec "sudo rm /etc/php5/fpm/pool.d/#{account.username}.conf", ->
        restartPhpfpm()
