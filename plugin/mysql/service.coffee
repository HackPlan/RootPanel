jade = require 'jade'
path = require 'path'
mysql = require 'mysql'
async = require 'async'

config = require '../../config'
plugin = require '../../core/plugin'

mAccount = require '../../core/model/account'

module.exports =
  enable: (account, callback) ->
    connection = mysql.createConnection config.plugins.mysql.connection
    connection.connect()

    connection.query "CREATE USER '#{account.username}'@'localhost' IDENTIFIED BY '#{mAccount.randomSalt()}';", (err, rows) ->
      throw err if err
      connection.end()
      callback()

  delete: (account, callback) ->
    connection = mysql.createConnection config.plugins.mysql.connection
    connection.connect()

    connection.query "DROP USER '#{account.username}'@'localhost';", (err, rows) ->
      throw err if err

      connection.query 'show databases;', (err, rows) ->
        throw err if err

        databases_to_delete = _.filter _.pluck(rows, 'Database'), (item) ->
          if item[..account.username.length] == "#{account.username}_"
            return true
          else
            return false

        async.each databases_to_delete, (name, callback) ->
          connection.query "DROP DATABASE `#{name}`;", (err, rows) ->
            throw err if err
            callback()
        , ->
          connection.end()
          callback()

  widget: (account, callback) ->
    jade.renderFile path.join(__dirname, 'view/widget.jade'), {}, (err, html) ->
      callback html

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
