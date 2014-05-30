jade = require 'jade'
path = require 'path'
async = require 'async'
mysql = require 'mysql'

config = require '../../core/config'
plugin = require '../../core/plugin'

mAccount = require '../../core/model/account'

module.exports =
  enable: (account, callback) ->
    plugin.systemOperate (callback) ->
      connection = mysql.createConnection config.plugins.mysql.connection
      connection.connect()

      connection.query "CREATE USER '#{account.username}'@'localhost' IDENTIFIED BY '#{mAccount.randomSalt()}';", (err, rows, fields) ->
        throw err if err
        connection.end()
        callback()
    , callback

  delete: (account, callback) ->
    plugin.systemOperate (callback) ->
      connection = mysql.createConnection config.plugins.mysql.connection
      connection.connect()

      connection.query "GRANT ALL PRIVILEGES ON `#{account.username}\\_%%` . * TO '#{account.username}'@'localhost';", (err, rows, fields) ->
        throw err if err
        connection.end()
        callback()
    , callback

  widget: (account, callback) ->
    jade.renderFile path.join(__dirname, 'view/widget.jade'), {}, (err, html) ->
      callback html

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
